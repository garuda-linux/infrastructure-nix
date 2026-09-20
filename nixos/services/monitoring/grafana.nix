{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.monitoring;

  port = garuda-lib.monitoring.ports.grafana;

  # The provisioned dashboards reference datasources by uid, so these are shared between
  # the datasource provisioning and the derived Chaotic dashboard copies.
  # The provisioned dashboards reference datasources by uid, so these are shared between
  # the datasource provisioning and the derived Chaotic dashboard copies.
  prometheusUid = "prometheus";
  chaoticPrometheusUid = "prometheus-chaotic";
  chaoticFlyUid = "fly-prometheus-chaotic";
  chaoticLokiUid = "loki-chaotic";
  lokiUid = "P8E80F9AEF21F6940";

  # Fly.io's managed Prometheus, reached through its HTTP API with a token.
  flyPrometheusUrl = "https://api.fly.io/prometheus/dr460nf1r3/";
  flyPrometheusUid = "fly-prometheus";

  # The Chaotic organization and the dashboards it additionally gets a copy of.
  chaoticOrgId = 2;
  organizations = [ "Chaotic" ];
  chaoticDashboardNames = [
    "build-queue.json"
    "chaotic-aur.json"
    "cloudflare-analytics.json"
    "cloudflare-threats.json"
    "cloudflare-r2.json"
    "fly-app.json"
    "fly-edge.json"
    "fly-instance.json"
    "mirrors.json"
  ];

  dashboardProvider = name: orgId: path: {
    inherit name orgId;
    type = "file";
    updateIntervalSeconds = 60;
    allowUiUpdates = false;
    options.path = path;
  };

  # Dashboards are authored as resources of the main organization. Grafana encodes the
  # owning organization in the resource namespace and picks datasources by uid, so the
  # Chaotic copies differ in exactly those two places
  chaoticDatasourceUid =
    name:
    if name == prometheusUid then
      chaoticPrometheusUid
    else if name == flyPrometheusUid then
      chaoticFlyUid
    else if name == lokiUid then
      chaoticLokiUid
    else
      name;

  # Rewrite every datasource reference (panel queries, variables, annotations
  # use {"name": ...} refs) to the Chaotic org's datasource copies. References
  # that do not point at a main-org datasource (built-ins, ${...} variables)
  # pass through untouched. This is only to lock down the Viewers view on purpose.
  rewriteChaoticDatasources =
    value:
    if lib.isAttrs value then
      lib.mapAttrs (
        attrName: attrValue:
        if
          attrName == "datasource" && lib.isAttrs attrValue && (attrValue.name or "") != ""
        then
          let
            uid = chaoticDatasourceUid attrValue.name;
          in
          if uid == attrValue.name then attrValue else { name = uid; uid = uid; }
        else
          rewriteChaoticDatasources attrValue
      ) value
    else if lib.isList value then
      map rewriteChaoticDatasources value
    else
      value;

  chaoticDashboard =
    name:
    let
      dashboard = lib.importJSON ./dashboards/${name};
      rewritten = rewriteChaoticDatasources dashboard;
      toChaotic =
        variable:
        if
          (variable.kind or "") == "DatasourceVariable" && (variable.spec.pluginId or "") == "prometheus"
        then
          lib.recursiveUpdate variable {
            spec.current = {
              text = "Prometheus";
              value = chaoticPrometheusUid;
            };
          }
        else if
          (variable.kind or "") == "DatasourceVariable" && (variable.spec.pluginId or "") == "loki"
        then
          lib.recursiveUpdate variable {
            spec.current = {
              text = "Loki";
              value = chaoticLokiUid;
            };
          }
        # The Chaotic org only gets its own zone: lock the zone variable down to
        # chaotic.cx so no other zone can be selected.
        else if (variable.kind or "") == "QueryVariable" && (variable.spec.name or "") == "zone" then
          lib.recursiveUpdate variable {
            spec = {
              regex = "^chaotic\\.cx$";
              multi = false;
              includeAll = false;
              current = {
                text = "chaotic.cx";
                value = "chaotic.cx";
              };
            };
          }
        else
          variable;
    in
    pkgs.writeText name (
      builtins.toJSON (
        lib.recursiveUpdate rewritten {
          metadata.namespace = "org-${toString chaoticOrgId}";
          spec.variables = map toChaotic rewritten.spec.variables;
        }
      )
    );

  chaoticDashboards = pkgs.linkFarm "grafana-chaotic-dashboards" (
    map (name: {
      inherit name;
      path = chaoticDashboard name;
    }) chaoticDashboardNames
  );

  # Grafana's GitLab connector only ever receives group full paths (from /api/v4/groups),
  # never access levels, so roles are matched on group membership. Longer paths are
  # checked first so that a subgroup rule wins over its parent group.
  gitlabRoleMapping = {
    "garuda-linux/devops" = "Admin";
    "garuda-linux" = "Editor";
  };

  gitlabRolePath =
    lib.concatStringsSep " || " (
      map (group: "contains(groups[*], '${group}') && '${gitlabRoleMapping.${group}}'") (
        builtins.sort (a: b: builtins.stringLength a > builtins.stringLength b) (
          builtins.attrNames gitlabRoleMapping
        )
      )
    )
    + " || 'Viewer'";

  adminPasswordScript = pkgs.writeShellScript "grafana-admin-password" ''
    exec ${lib.getExe config.services.grafana.package} cli \
      --homepath ${config.services.grafana.dataDir} \
      admin reset-admin-password --password-from-stdin \
      < ${config.sops.secrets."grafana/admin_password".path}
  '';

  # Maps sadly need the token to not render an overlay.
  # NOTE: This runs under Grafana's hardened systemd unit (syscall filter)
  renderDashboardsScript = pkgs.writeShellScript "grafana-render-dashboards" ''
    set -euo pipefail
    dest=${config.services.grafana.dataDir}/dashboards-rendered
    key=$(<${config.sops.secrets."grafana/carto_key".path})
    mkdir -p "$dest/garuda" "$dest/chaotic"
    rm -f "$dest/garuda"/* "$dest/chaotic"/* || true
    render() {
      local src=$1 dst=$2 f content
      for f in "$src"/*.json; do
        content=$(<"$f")
        printf '%s' "''${content//__CARTO_KEY__/$key}" > "$dst/''${f##*/}"
      done
    }
    render ${./dashboards} "$dest/garuda"
    render ${chaoticDashboards} "$dest/chaotic"
  '';
in
{
  options.garuda.monitoring.grafana.enable = lib.mkEnableOption "Enable Grafana";

  config = lib.mkIf (cfg.enable && cfg.grafana.enable) {
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
              uid = prometheusUid;
            }
            # Chaotic org (id 2) gets its own copy
            ++ lib.optional cfg.prometheus.enable {
              access = "proxy";
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString cfg.prometheus.port}";
              isDefault = true;
              uid = chaoticPrometheusUid;
              orgId = chaoticOrgId;
            }
            ++ lib.optional cfg.loki.enable {
              access = "proxy";
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:${toString cfg.loki.port}";
              uid = lokiUid;
            }
            ++ lib.optional cfg.loki.enable {
              access = "proxy";
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:${toString cfg.loki.port}";
              uid = chaoticLokiUid;
              orgId = chaoticOrgId;
            }
            ++ lib.optional (cfg.prometheus.enable && cfg.prometheus.alertmanager.enable) {
              access = "proxy";
              name = "Alertmanager";
              type = "alertmanager";
              url = "http://127.0.0.1:${toString cfg.prometheus.alertmanager.port}";
            }
            # https://fly.io/docs/monitoring/metrics/#external-or-self-hosted-grafana
            ++ [
              {
                access = "proxy";
                name = "Fly.io";
                type = "prometheus";
                url = flyPrometheusUrl;
                uid = flyPrometheusUid;
                jsonData = {
                  httpHeaderName1 = "Authorization";
                };
                secureJsonData = {
                  httpHeaderValue1 = "$__file{${config.sops.secrets."grafana/fly_token".path}}";
                };
              }
              # Chaotic org (id 2) gets its own copy under a different uid, so the vendored Fly dashboards resolve
              {
                access = "proxy";
                name = "Fly.io";
                type = "prometheus";
                url = flyPrometheusUrl;
                uid = chaoticFlyUid;
                orgId = chaoticOrgId;
                jsonData = {
                  httpHeaderName1 = "Authorization";
                };
                secureJsonData = {
                  httpHeaderValue1 = "$__file{${config.sops.secrets."grafana/fly_token".path}}";
                };
              }
            ];
        };
        dashboards.settings = {
          apiVersion = 1;
          providers = [
            (dashboardProvider "garuda" 1 "${config.services.grafana.dataDir}/dashboards-rendered/garuda")
            (dashboardProvider "chaotic" chaoticOrgId "${config.services.grafana.dataDir}/dashboards-rendered/chaotic")
          ];
        };
      };
      settings = {
        analytics.reporting_enabled = false;

        live = {
          allowed_origins = [ "https://${cfg.domain}" ];
        };

        public_dashboards.enabled = true;

        security = {
          admin_email = "root@garudalinux.org";
          secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
        };

        server = {
          http_addr = "0.0.0.0";
          http_port = port;
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
          client_id = "$__file{${config.sops.secrets."grafana/gitlab_client_id".path}}";
          client_secret = "$__file{${config.sops.secrets."grafana/gitlab_client_secret".path}}";
          auth_url = "https://gitlab.com/oauth/authorize";
          token_url = "https://gitlab.com/oauth/token";
          api_url = "https://gitlab.com/api/v4";
          scopes = "read_api read_user openid profile email";
          allowed_groups = "garuda-linux";
          role_attribute_path = gitlabRolePath;
          # Garuda DevOps is automatically also a Chaotic-AUR admin.
          org_mapping = "garuda-linux/devops:Chaotic:Admin";
          skip_org_role_sync = false;
          use_pkce = true;
          use_refresh_token = true;
        };

        "auth.github" = {
          enabled = true;
          name = "GitHub";
          icon = "github";
          allow_sign_up = true;
          auto_login = false;
          client_id = "$__file{${config.sops.secrets."grafana/github_client_id".path}}";
          client_secret = "$__file{${config.sops.secrets."grafana/github_client_secret".path}}";
          scopes = "user:email,read:org";
          auth_url = "https://github.com/login/oauth/authorize";
          token_url = "https://github.com/login/oauth/access_token";
          api_url = "https://api.github.com/user";
          allowed_organizations = "chaotic-aur";
          team_ids = "3941199,3941202,4804177";
          org_mapping = "@chaotic-aur/devops:Chaotic:Admin @chaotic-aur/co-maintainers:Chaotic:Viewer @chaotic-aur/mirrorers:Chaotic:Viewer";
        };
      };
    };

    # Grafana only applies `security.admin_password` while creating the admin user, so an
    # install that already has one silently keeps its old password.
    systemd.services.grafana.serviceConfig.ExecStartPre = [ adminPasswordScript renderDashboardsScript ];

    sops.secrets = {
      "grafana/carto_key" = {
        owner = "grafana";
      };      "grafana/admin_password" = {
        owner = "grafana";
      };
      "grafana/fly_token" = {
        owner = "grafana";
      };
      "grafana/gitlab_client_id" = {
        owner = "grafana";
      };
      "grafana/gitlab_client_secret" = {
        owner = "grafana";
      };
      "grafana/github_client_id" = {
        owner = "grafana";
      };
      "grafana/github_client_secret" = {
        owner = "grafana";
      };
      "grafana/smtp_password" = {
        owner = "grafana";
      };
      "grafana/secret_key" = {
        owner = "grafana";
      };
    };

    systemd.services.grafana-organizations = {
      description = "Ensure Grafana organizations exist";
      after = [ "grafana.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        TimeoutStartSec = "5min";
      };
      script =
        let
          systemctl = lib.getExe' pkgs.systemd "systemctl";
          grafana = config.services.grafana.package;

          # Grafana aborts on startup when provisioning references an organization that
          # does not exist yet. Such organizations are therefore created through a
          # throwaway instance that never reads the provisioning directory.
          emptyProvisioning = pkgs.runCommand "grafana-empty-provisioning" { } "mkdir -p $out";
        in
        ''
          set -euo pipefail

          api="http://127.0.0.1:${toString port}/api"
          password="$(cat ${config.sops.secrets."grafana/admin_password".path})"
          curl="${lib.getExe pkgs.curl}"
          bootstrap=""

          cleanup() {
            if [ -n "$bootstrap" ]; then
              kill "$bootstrap" 2>/dev/null || true
              wait "$bootstrap" 2>/dev/null || true
            fi
            ${systemctl} start grafana.service || true
          }
          trap cleanup EXIT

          healthy() {
            i=0
            while [ "$i" -lt 40 ]; do
              if "$curl" --silent --fail --user "admin:$password" "$1/health" >/dev/null 2>&1; then
                return 0
              fi
              sleep 1
              i=$((i + 1))
            done
            return 1
          }

          status() {
            "$curl" --silent --output /dev/null --write-out '%{http_code}' \
              --user "admin:$password" "$1" || echo 000
          }

          if ! healthy "$api"; then
            ${systemctl} stop grafana.service
            # Same homepath and paths as the server, so this writes to the same database.
            GF_SECURITY_ADMIN_PASSWORD="$password" \
            GF_SECURITY_SECRET_KEY="$(cat ${config.sops.secrets."grafana/secret_key".path})" \
              ${lib.getExe grafana} server \
              --homepath ${config.services.grafana.dataDir} \
              cfg:paths.provisioning=${emptyProvisioning} \
              cfg:server.http_addr=127.0.0.1 \
              cfg:server.http_port=${toString port} \
              cfg:security.admin_user=admin \
              cfg:analytics.reporting_enabled=false &
            bootstrap=$!
            healthy "$api"
          fi

          created=0
          ${lib.concatMapStrings (org: ''
            code="$(status "$api/orgs/name/${org}")"
            case "$code" in
              200) ;;
              404)
                if response="$("$curl" --silent --show-error --fail-with-body \
                    --user "admin:$password" \
                    --header "Content-Type: application/json" \
                    --data '{"name":"${org}"}' "$api/orgs")"; then
                  echo "created organization ${org}"
                  created=1
                else
                  echo "failed to create organization ${org}: $response" >&2
                fi
                ;;
              *)
                echo "could not look up organization ${org}: HTTP $code" >&2
                ;;
            esac
          '') organizations}

          if [ -n "$bootstrap" ]; then
            cleanup
            bootstrap=""
          elif [ "$created" = 1 ]; then
            ${systemctl} restart grafana.service
          fi
        '';
    };
  };
}
