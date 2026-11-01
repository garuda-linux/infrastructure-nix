# shellcheck shell=bash
if [ "${1:-}" = shell ]; then
  shift

  if [ -n "${GCX_SHELL:-}" ]; then
    echo "gcx: already in a gcx shell" >&2
    exit 1
  fi

  unlocked=0
  if [ -z "${BW_SESSION:-}" ]; then
    echo "gcx: unlocking bw (${BITWARDENCLI_APPDATA_DIR:-default data dir})" >&2
    BW_SESSION=$(bw unlock --raw </dev/tty)
    export BW_SESSION
    unlocked=1
  fi

  status=0
  for key in GRAFANA_SERVER GRAFANA_ORG_ID GRAFANA_TOKEN; do
    if ! value=$(secretspec get "$key" --reason "gcx shell"); then
      status=1
      break
    fi
    export "$key=$value"
  done

  if [ "$unlocked" = 1 ]; then
    bw lock >/dev/null 2>&1 || true
  fi
  unset BW_SESSION

  if [ "$status" != 0 ]; then
    echo "gcx: could not resolve the Grafana settings from secretspec.toml" >&2
    exit 1
  fi
  export GCX_SHELL=1

  echo "gcx: Grafana credentials for $GRAFANA_SERVER loaded, exit the shell to drop them" >&2
  exec "${SHELL:-bash}" "$@"
fi

if [ -z "${GRAFANA_TOKEN:-}" ]; then
  echo "gcx: no Grafana credentials here, run 'gcx shell' first" >&2
  exit 1
fi
exec "$GCX_BIN" "$@"
