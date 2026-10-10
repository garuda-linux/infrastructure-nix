"""Alertmanager -> FCM relay.

Receives Alertmanager webhooks on /hook/<source>, trims them to the push
contract and forwards them as FCM data messages.

Config (environment):
  FIREBASE_PROJECT_ID               Firebase project id (target of FCM sends)
  GOOGLE_APPLICATION_CREDENTIALS    Path to the service-account JSON key.
  FCM_TOKENS_JSON                   JSON map of source name -> watch FCM token,
                                    e.g. '{"prod": "fcm:APA91...", "homelab": "fcm:APA91..."}'.
                                    The token is shown in the watch app under Settings.
  RELAY_SECRET                      Optional. When set, Alertmanager must send
                                    'Authorization: Bearer <secret>' (see README).
  RELAY_PORT                        Listen port, default 8099.
"""

import http.server
import json
import os
import threading
import urllib.error
import urllib.request

import google.auth
import google.auth.transport.requests

FCM_SCOPE = ["https://www.googleapis.com/auth/firebase.messaging"]
MAX_ALERTS_PER_PUSH = 12
MAX_DATA_BYTES = 3900

PROJECT_ID = os.environ["FIREBASE_PROJECT_ID"]
TOKENS = json.loads(os.environ.get("FCM_TOKENS_JSON", "{}"))
SECRET = os.environ.get("RELAY_SECRET", "")
PORT = int(os.environ.get("RELAY_PORT", "8099"))

_creds, _creds_project = google.auth.default(scopes=FCM_SCOPE)
_creds_lock = threading.Lock()


def access_token() -> str:
    with _creds_lock:
        if not _creds.valid:
            _creds.refresh(google.auth.transport.requests.Request())
        return _creds.token


def trim_alert(alert: dict) -> dict:
    labels = alert.get("labels", {})
    annotations = alert.get("annotations", {})
    return {
        "fp": alert.get("fingerprint", ""),
        "status": alert.get("status", "firing"),
        "name": labels.get("alertname", ""),
        "severity": labels.get("severity", ""),
        "summary": annotations.get("summary", ""),
        "instance": labels.get("instance", ""),
        "startsAt": alert.get("startsAt", ""),
    }


def fcm_send(token: str, source: str, alerts: list) -> tuple[int, str]:
    firing_first = sorted(alerts, key=lambda a: (a["status"] != "firing", a["name"]))
    trimmed = firing_first[:MAX_ALERTS_PER_PUSH]
    while len(json.dumps(trimmed).encode()) > MAX_DATA_BYTES and trimmed:
        trimmed.pop()
    body = json.dumps(
        {
            "message": {
                "token": token,
                "data": {
                    "type": "alerts",
                    "source": source,
                    "alerts": json.dumps(trimmed),
                },
            }
        }
    ).encode()
    req = urllib.request.Request(
        f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send",
        data=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token()}",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.status, resp.read().decode()[:200]
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()[:200]


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # noqa: A002 - signature required by BaseHTTPRequestHandler
        pass

    def do_POST(self):
        parts = self.path.strip("/").split("/")
        if len(parts) != 2 or parts[0] != "hook":
            self.send_error(404)
            return
        source = parts[1]
        if SECRET and self.headers.get("Authorization") != f"Bearer {SECRET}":
            self.send_error(401)
            return
        token = TOKENS.get(source)
        if not token:
            self.send_error(404, f"unknown source: {source}")
            return
        length = int(self.headers.get("Content-Length", 0))
        try:
            payload = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_error(400, "invalid JSON")
            return
        alerts = [trim_alert(a) for a in payload.get("alerts", [])]
        status, detail = fcm_send(token, source, alerts)
        print(f"source={source} alerts={len(alerts)} fcm={status} {detail}", flush=True)
        body = b'{"ok": true}' if status < 300 else b'{"ok": false}'
        self.send_response(200 if status < 300 else 502)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    if not PROJECT_ID or not TOKENS:
        raise SystemExit("FIREBASE_PROJECT_ID and FCM_TOKENS_JSON are required")
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"relay listening on 127.0.0.1:{PORT}, sources={sorted(TOKENS)}", flush=True)
    server.serve_forever()
