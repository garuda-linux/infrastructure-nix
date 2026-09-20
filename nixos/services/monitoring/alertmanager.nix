{
  config,
  lib,
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
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
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
        receivers = [
          {
            name = "garuda";
            webhook_configs = lib.optional (cfg.prometheus.alertmanager.webhookUrl != null) {
              url = cfg.prometheus.alertmanager.webhookUrl;
            };
            telegram_configs = lib.optional cfg.prometheus.alertmanager.telegram.enable {
              bot_token = "$TELEGRAM_BOT_TOKEN";
              chat_id = cfg.prometheus.alertmanager.telegram.chatId;
              api_url = cfg.prometheus.alertmanager.telegram.apiUrl;
              parse_mode = cfg.prometheus.alertmanager.telegram.parseMode;
              message = ''
                {{- define "garuda.alert" -}}
                <b>{{ .Labels.alertname }}</b>{{ with .Labels.instance }}
                <b>Instance:</b> {{ . }}{{ end }}{{ with .Labels.name }}
                <b>Name:</b> {{ . }}{{ end }}{{ with .Labels.severity }}
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
              inherit (cfg.prometheus.alertmanager.email) from;
              inherit (cfg.prometheus.alertmanager.email) smarthost;
              auth_username = cfg.prometheus.alertmanager.email.authUsername;
              auth_password = "$EMAIL_PASSWORD";
            };
          }
        ];
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
