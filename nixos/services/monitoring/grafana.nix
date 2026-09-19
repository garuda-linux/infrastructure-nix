{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.garuda.monitoring;
in
{
  options.garuda.monitoring.grafana = with lib; {
    enable = mkEnableOption "Enable Grafana";

    port = mkOption {
      default = 3010;
      type = types.port;
      description = mdDoc ''
        The port for Grafana to listen on.
      '';
    };

    adminEmail = mkOption {
      default = "root@garudalinux.org";
      type = types.str;
      description = mdDoc ''
        The admin email for Grafana.
      '';
    };

    gitlabUrl = mkOption {
      default = "https://gitlab.com";
      type = types.str;
      description = mdDoc ''
        Base URL of the GitLab instance used for Grafana OAuth.
      '';
    };

    gitlabClientId = mkOption {
      default = null;
      type = with types; nullOr str;
      description = mdDoc ''
        OAuth application ID from the GitLab application
        Callback URL: https://<domain>/login/gitlab.
        If null, read from the grafana/gitlab_client_id sops secret.
      '';
    };

    allowedGroups = mkOption {
      default = [ "garuda-linux" ];
      type = types.listOf types.str;
      description = mdDoc ''
        GitLab groups allowed to sign in to Grafana.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.grafana.enable && options ? sops) {
    services.grafana = {
      enable = true;
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          datasources =
            lib.optional cfg.prometheus.enable {
              access = "proxy";
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString cfg.prometheus.port}";
              isDefault = true;
              uid = "prometheus";
            }
            ++ lib.optional cfg.loki.enable {
              access = "proxy";
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:${toString cfg.loki.port}";
            }
            ++ lib.optional (cfg.prometheus.enable && cfg.prometheus.alertmanager.enable) {
              access = "proxy";
              name = "Alertmanager";
              type = "alertmanager";
              url = "http://127.0.0.1:${toString cfg.prometheus.alertmanager.port}";
            };
        };
      };
      settings = {
        analytics.reporting_enabled = false;

        live = {
          allowed_origins = [ "https://${cfg.domain}" ];
        };

        security = {
          admin_email = cfg.grafana.adminEmail;
          secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        };

        server = {
          http_addr = "0.0.0.0";
          http_port = cfg.grafana.port;
          protocol = "http";
          root_url = "https://${cfg.domain}";
        };

        smtp = {
          enabled = true;
          host = "mail.garudalinux.org:465";
          from_address = "noreply@garudalinux.org";
          user = "noreply@garudalinux.org";
          password = "$__file{${config.sops.secrets."grafana/smtp_password".path}}";
        };

        auth = {
          oauth_allow_insecure_email_lookup = true;
          disable_login_form = false;
        };

        "auth.gitlab" = {
          enabled = true;
          name = "GitLab";
          icon = "gitlab";
          allow_sign_up = true;
          auto_login = false;
          client_id =
            if cfg.grafana.gitlabClientId != null then
              cfg.grafana.gitlabClientId
            else
              "$__file{${config.sops.secrets."grafana/gitlab_client_id".path}}";
          client_secret = "$__file{${config.sops.secrets."grafana/gitlab_client_secret".path}}";
          auth_url = "${cfg.grafana.gitlabUrl}/oauth/authorize";
          token_url = "${cfg.grafana.gitlabUrl}/oauth/token";
          api_url = "${cfg.grafana.gitlabUrl}/api/v4";
          scopes = "read_api read_user openid profile email";
          allowed_groups = lib.concatStringsSep " " cfg.grafana.allowedGroups;
          role_attribute_path = "contains(groups[*], 'Owner') && 'Admin' || contains(groups[*], 'Maintainer') && 'Editor' || 'Viewer'";
          skip_org_role_sync = false;
          use_pkce = true;
          use_refresh_token = true;
        };
      };
    };

    sops.secrets = {
      "grafana/gitlab_client_id" = {
        owner = "grafana";
      };
      "grafana/gitlab_client_secret" = {
        owner = "grafana";
      };
      "grafana/smtp_password" = {
        owner = "grafana";
      };
      "grafana/secret_key" = {
        owner = "grafana";
      };
    };
  };
}
