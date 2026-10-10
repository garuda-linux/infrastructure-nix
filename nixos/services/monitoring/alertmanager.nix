{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.monitoring;
in
{
  options.garuda.monitoring.prometheus.alertmanager = with lib; {
    enable = mkEnableOption "Enable Alertmanager";

    port = mkOption {
      default = 9093;
      type = types.port;
      description = mdDoc ''
        The port for Alertmanager to listen on.
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/root/alertmanager.env";
      description = mdDoc ''
        File to load as environment file. Environment variables
        from this file will be interpolated into the config file
        using envsubst with this syntax:
        `$ENVIRONMENT ''${VARIABLE}`

        Required variables:
        - TELEGRAM_BOT_TOKEN (if telegram enabled)
        - EMAIL_PASSWORD (if email enabled)
        - FCM_RELAY_SECRET (if fcm enabled)
      '';
    };

    webhookUrl = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = mdDoc ''
        Optional webhook URL for default receiver.
      '';
    };

    telegram = {
      enable = mkEnableOption "Enable Telegram notifications";

      chatId = mkOption {
        default = 595698043;
        type = types.int;
        description = mdDoc ''
          Telegram chat ID to send alerts to. Not sensitive, so this
          lives in the config directly instead of the environment file
          (Alertmanager validates the config at build time, where
          environment variables are not available).
        '';
      };

      apiUrl = mkOption {
        default = "https://api.telegram.org";
        type = types.str;
        description = mdDoc ''
          Telegram API URL.
        '';
      };

      parseMode = mkOption {
        default = "HTML";
        type = types.enum [
          "MarkdownV2"
          "Markdown"
          "HTML"
        ];
        description = mdDoc ''
          Parse mode for Telegram message.
        '';
      };
    };

    fcm = {
      enable = mkEnableOption "Enable push notifications via the Alertmanager to FCM relay";

      port = mkOption {
        default = 8099;
        type = types.port;
        description = mdDoc ''
          The port for the relay to listen on (always 127.0.0.1).
        '';
      };

      source = mkOption {
        default = "garuda";
        type = types.str;
        description = mdDoc ''
          Source name sent with each push. Must be a key of
          FCM_TOKENS_JSON in the relay's environment file.
        '';
      };

      severities = mkOption {
        default = [
          "critical"
          "warning"
        ];
        type = types.listOf types.str;
        description = mdDoc ''
          Alert severities that are pushed to the watch.
        '';
      };

      environmentFile = mkOption {
        type = types.path;
        example = "/run/secrets/alertmanager-fcm.env";
        description = mdDoc ''
          Environment file for the relay. Required variables:
          - FIREBASE_PROJECT_ID
          - FCM_TOKENS_JSON (JSON map of source name to FCM token)
          - RELAY_SECRET (must match FCM_RELAY_SECRET of Alertmanager)
        '';
      };

      credentialsFile = mkOption {
        type = types.path;
        example = "/run/secrets/fcm-service-account.json";
        description = mdDoc ''
          Firebase service-account JSON key, passed to the relay
          via systemd LoadCredential.
        '';
      };
    };

    email = {
      enable = mkEnableOption "Enable email notifications";

      to = mkOption {
        type = types.str;
        description = mdDoc ''
          Email address to send alerts to.
        '';
      };

      from = mkOption {
        type = types.str;
        description = mdDoc ''
          Sender email address.
        '';
      };

      smarthost = mkOption {
        type = types.str;
        description = mdDoc ''
          SMTP server address (host:port).
        '';
      };

      authUsername = mkOption {
        type = types.str;
        description = mdDoc ''
          SMTP username.
        '';
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.prometheus.enable && cfg.prometheus.alertmanager.enable) {
    systemd.services.alertmanager-fcm = lib.mkIf cfg.prometheus.alertmanager.fcm.enable {
      description = "Alertmanager to FCM push relay";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        RELAY_PORT = toString cfg.prometheus.alertmanager.fcm.port;
        GOOGLE_APPLICATION_CREDENTIALS = "%d/service-account.json";
      };
      serviceConfig = {
        ExecStart = lib.getExe pkgs.alertmanager-fcm;
        EnvironmentFile = cfg.prometheus.alertmanager.fcm.environmentFile;
        LoadCredential = "service-account.json:${cfg.prometheus.alertmanager.fcm.credentialsFile}";
        Restart = "always";
        RestartSec = 5;
        DynamicUser = true;
        CapabilityBoundingSet = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
      };
    };

    services.prometheus.alertmanager = {
      inherit (cfg.prometheus.alertmanager) enable;
      inherit (cfg.prometheus.alertmanager) port;
      inherit (cfg.prometheus.alertmanager) environmentFile;
      configuration = {
        global = {
          resolve_timeout = "5m";
        };
        route = {
          receiver = "garuda";
          group_by = [
            "alertname"
            "instance"
          ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
          # Host-global alerts keep firing notifications, drop the recovered spam
          routes =
            let
              lowSeverity = {
                matchers = [ ''severity=~"warning|info"'' ];
                repeat_interval = "24h";
              };
            in
            # continue = true lets the alert also reach the Telegram routes below
            lib.optional cfg.prometheus.alertmanager.fcm.enable {
              matchers = [
                ''severity=~"${lib.concatStringsSep "|" cfg.prometheus.alertmanager.fcm.severities}"''
              ];
              receiver = "fcm";
              continue = true;
            }
            ++ [
              {
                matchers = [ ''scope="host"'' ];
                receiver = "garuda-no-resolved";
                routes = [ lowSeverity ];
              }
              lowSeverity
            ];
        };
        # nspawn containers share the host kernel, so host-global metrics
        # (meminfo, vmstat, /proc/stat, /sys, ...) read identically inside
        # every container. Container-local rules are not inhibited.
        inhibit_rules = [
          {
            source_matchers = [
              ''scope="host"''
              ''job="node-hosts"''
            ];
            target_matchers = [
              ''scope="host"''
              ''job=~"node-.+-containers"''
            ];
            equal = [ "alertname" ];
          }
        ];
        receivers =
          let
            mkGarudaReceiver = name: sendResolved: {
              inherit name;
              webhook_configs = lib.optional (cfg.prometheus.alertmanager.webhookUrl != null) {
                url = cfg.prometheus.alertmanager.webhookUrl;
                send_resolved = sendResolved;
              };
              telegram_configs = lib.optional cfg.prometheus.alertmanager.telegram.enable {
                bot_token = "$TELEGRAM_BOT_TOKEN";
                send_resolved = sendResolved;
                chat_id = cfg.prometheus.alertmanager.telegram.chatId;
                api_url = cfg.prometheus.alertmanager.telegram.apiUrl;
                parse_mode = cfg.prometheus.alertmanager.telegram.parseMode;
                message = ''
                  {{- define "garuda.alert" -}}
                  <b>{{ .Labels.alertname }}</b>{{ with .Labels.instance }}
                  <b>Instance:</b> {{ . }}{{ end }}{{ with .Labels.name }}
                  <b>Name:</b> {{ . }}{{ end }}{{ with .Labels.device }}
                  <b>Device:</b> {{ . }}{{ end }}{{ with .Labels.severity }}
                  <b>Severity:</b> {{ . }}{{ end }}{{ with .Labels.state }}
                  <b>State:</b> {{ . }}{{ end }}
                  {{ end -}}
                  {{ if .Alerts.Firing -}}
                  🚨 <b>Alert Firing:</b>
                  {{ range .Alerts.Firing }}{{ template "garuda.alert" . }}
                  {{ end }}{{ end -}}
                  {{ if .Alerts.Resolved -}}
                  ✅ <b>Recovered:</b>
                  {{ range .Alerts.Resolved }}{{ template "garuda.alert" . }}
                  {{ end }}{{ end -}}
                '';
              };
              email_configs = lib.optional cfg.prometheus.alertmanager.email.enable {
                inherit (cfg.prometheus.alertmanager.email) to;
                send_resolved = sendResolved;
                inherit (cfg.prometheus.alertmanager.email) from;
                inherit (cfg.prometheus.alertmanager.email) smarthost;
                auth_username = cfg.prometheus.alertmanager.email.authUsername;
                auth_password = "$EMAIL_PASSWORD";
              };
            };
          in
          [
            (mkGarudaReceiver "garuda" true)
            (mkGarudaReceiver "garuda-no-resolved" false)
          ]
          # Resolved notifications are what clear alerts on the fcm receiver
          ++ lib.optional cfg.prometheus.alertmanager.fcm.enable {
            name = "fcm";
            webhook_configs = [
              {
                url = "http://127.0.0.1:${toString cfg.prometheus.alertmanager.fcm.port}/hook/${cfg.prometheus.alertmanager.fcm.source}";
                send_resolved = true;
                http_config.authorization.credentials = "$FCM_RELAY_SECRET";
              }
            ];
          };
      };
    };

    services.prometheus.alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString cfg.prometheus.alertmanager.port}" ];
          }
        ];
      }
    ];
  };
}
