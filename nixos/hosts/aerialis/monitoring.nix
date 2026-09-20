{
  config,
  garuda-lib,
  sources,
  ...
}:
let
  mon = garuda-lib.monitoring;

  units = [
    "grafana.service"
    "prometheus.service"
    "alertmanager.service"
    "prometheus-tailscale-exporter.service"
    "loki.service"
  ];
in
{
  imports = sources.defaultModules ++ [
    ../../modules
  ];

  # Own Tailnet identity so Prometheus scrapes mirrors/hosts directly
  # via MagicDNS instead of socat hairpins on the host.
  services.garuda-tailscale.enable = true;

  garuda.monitoring = {
    enable = true;

    domain = "grafana.garudalinux.net";
    baseDomain = "garudalinux.net";

    buildQueue.enable = true;

    grafana.enable = true;

    prometheus = {
      enable = true;
      port = mon.ports.prometheus;

      alertmanager = {
        enable = true;
        port = mon.ports.alertmanager;
        environmentFile = config.sops.templates."alertmanager-env".path;
        telegram.enable = true;
      };

      inherit (mon) smartctlTargets;

      inherit (mon) borgmaticTargets;

      nodeExporter = {
        enable = true;
        port = mon.ports.nodeExporter;
      };

      postgresExporter = {
        enable = true;
        environmentFile = config.sops.templates."postgres-exporter-env".path;
      };

      tailscaleExporter = {
        enable = true;
        port = 9813;
        environmentFile = config.sops.templates."tailscale-exporter-env".path;
      };

      cloudflareExporter = {
        enable = true;
        port = mon.ports.cloudflareExporter;
        environmentFile = config.sops.templates."cloudflare-exporter-env".path;
      };

      applicationTargets = [
        {
          name = "dovecot";
          address = mon.aerialisContainers.mail;
          port = mon.ports.dovecotMetrics;
        }
        {
          name = "postfix";
          address = mon.aerialisContainers.mail;
          port = mon.ports.postfixExporter;
        }
        {
          name = "redis";
          address = mon.aerialisContainers.chaotic-backend;
          port = mon.ports.redisExporter;
        }
      ];

      scrapeConfigs = [
        {
          job_name = "node-hosts";
          static_configs = map (t: {
            targets = [ t.target ];
            labels = {
              instance = t.name;
            };
          }) mon.nodeHostTargets;
        }
        {
          job_name = "node-aerialis-containers";
          static_configs = map (t: {
            targets = [ t.target ];
            labels = {
              inherit (t) instance;
            };
          }) mon.nodeContainerTargets;
        }
        {
          job_name = "node-stormwing-containers";
          static_configs = map (t: {
            targets = [ t.target ];
            labels = {
              inherit (t) instance;
            };
          }) mon.stormwingNodeContainerTargets;
        }
        {
          job_name = "nginx";
          static_configs = [
            {
              targets = mon.nginxTargets;
            }
          ];
        }
        {
          job_name = "cloudflared";
          static_configs = [
            {
              targets = mon.cloudflaredTargets;
            }
          ];
        }
        {
          job_name = "gitlab-runner";
          static_configs = [
            {
              targets = mon.gitlabRunnerTargets;
            }
          ];
          scrape_interval = "30s";
        }
        {
          job_name = "node-chaotic-mirrors";
          static_configs = map (m: {
            targets = [ m.target ];
            labels = {
              instance = m.name;
            };
          }) mon.chaoticMirrorTargets;
        }
        {
          job_name = "loki";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString mon.ports.loki}" ];
            }
          ];
        }
        {
          job_name = "alertmanager";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString mon.ports.alertmanager}" ];
            }
          ];
        }
      ];
    };

    loki = {
      enable = true;
      port = mon.ports.loki;
      dataDir = "/var/lib/loki";
    };

    fluent-bit = {
      enable = true;
      lokiAddress = "127.0.0.1";
      lokiPort = mon.ports.loki;
      extraSystemdUnits = units;
    };
  };

  networking.firewall = {
    allowedTCPPorts = with mon.ports; [
      grafana
      loki
      prometheus
      alertmanager
    ];
    interfaces."eth0".allowedTCPPorts = [ mon.ports.nodeExporter ];
  };

  sops.secrets."monitoring/telegram_bot_token" = { };
  sops.templates."alertmanager-env" = {
    mode = "0400";
    content = ''
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."monitoring/telegram_bot_token"}
    '';
  };

  sops.secrets."grafana/gitlab_client_secret" = {
    owner = "grafana";
  };
  sops.secrets."grafana/smtp_password" = {
    owner = "grafana";
  };
  sops.secrets."grafana/secret_key" = {
    owner = "grafana";
  };

  sops.secrets."postgres/netdata" = { };
  sops.templates."postgres-exporter-env" = {
    owner = "postgres-exporter";
    group = "postgres-exporter";
    mode = "0400";
    content = "PGPASSWORD=${config.sops.placeholder."postgres/netdata"}";
  };

  sops.secrets."tailscale/oauth_client_id" = { };
  sops.secrets."tailscale/oauth_client_secret" = { };
  sops.templates."tailscale-exporter-env" = {
    mode = "0400";
    content = ''
      TAILSCALE_TAILNET=${mon.tailnetDomain}
      TAILSCALE_OAUTH_CLIENT_ID=${config.sops.placeholder."tailscale/oauth_client_id"}
      TAILSCALE_OAUTH_CLIENT_SECRET=${config.sops.placeholder."tailscale/oauth_client_secret"}
    '';
  };

  sops.secrets."cloudflare/exporter_api_token" = { };
  sops.templates."cloudflare-exporter-env" = {
    mode = "0400";
    content = ''
      CF_API_TOKEN=${config.sops.placeholder."cloudflare/exporter_api_token"}
    '';
  };

  system.stateVersion = "26.11";
}
