{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.monitoring;

  prometheusRulesFile =
    name: groups: pkgs.writeText "${name}.yml" (builtins.toJSON { inherit groups; });

  defaultRules = prometheusRulesFile "node-exporter" (
    import ./prometheus-rules/node-exporter-rules.nix
  );

  smartctlRules = prometheusRulesFile "smartctl-exporter" (
    import ./prometheus-rules/smartctl-exporter-rules.nix
  );

  borgmaticRules = prometheusRulesFile "borgmatic" (import ./prometheus-rules/borgmatic-rules.nix);

  postgresRules = prometheusRulesFile "postgres-exporter" (
    import ./prometheus-rules/postgres-exporter-rules.nix
  );

  nginxRules = prometheusRulesFile "nginx-exporter" (
    import ./prometheus-rules/nginx-exporter-rules.nix
  );

  selfMonitoringRules = prometheusRulesFile "self-monitoring" (
    import ./prometheus-rules/self-monitoring-rules.nix
  );

  mailRules = prometheusRulesFile "mail" (import ./prometheus-rules/mail-rules.nix);

  redisRules = prometheusRulesFile "redis" (import ./prometheus-rules/redis-rules.nix);
in
{
  options.garuda.monitoring.prometheus = with lib; {
    enable = mkEnableOption "Enable Prometheus";

    port = mkOption {
      default = 9090;
      type = types.port;
      description = mdDoc ''
        The port for Prometheus to listen on.
      '';
    };

    retentionTime = mkOption {
      default = "30d";
      type = types.str;
      description = mdDoc ''
        How long Prometheus retains samples before the TSDB deletes them.
      '';
    };

    retentionSize = mkOption {
      default = "20GB";
      type = types.nullOr types.str;
      description = mdDoc ''
        Maximum TSDB size before the oldest blocks get deleted. Data is
        removed as soon as either this or retentionTime is exceeded. Set to
        null to only bound retention by time.
      '';
    };

    queryMaxSamples = mkOption {
      default = 50000000;
      type = types.int;
      description = mdDoc ''
        Maximum number of samples a single query may load (--query.max-samples).
        Bounds the memory a heavy query can use.
      '';
    };

    extraFlags = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = mdDoc ''
        Additional command line flags for Prometheus.
      '';
    };

    nodeExporter = {
      enable = mkEnableOption "Enable Prometheus node_exporter";
      port = mkOption {
        default = 3021;
        type = types.port;
        description = mdDoc ''
          The port for node_exporter to listen on.
        '';
      };
      textfileDirectory = mkOption {
        default = "/var/lib/node-exporter";
        type = types.str;
        description = mdDoc ''
          Directory for node_exporter's textfile collector. Host info such as
          the NixOS version, revision and build timestamp is written here.
        '';
      };
    };

    smartctlExporter = {
      enable = mkEnableOption "Enable Prometheus smartctl_exporter (autodiscovers all disks)";
      port = mkOption {
        default = 9633;
        type = types.port;
        description = mdDoc ''
          The port for smartctl_exporter to listen on.
        '';
      };
    };

    borgmaticExporter = {
      enable = mkEnableOption "Enable Prometheus borgmatic exporter";
      port = mkOption {
        default = 9996;
        type = types.port;
        description = mdDoc ''
          The port for the borgmatic exporter to listen on.
        '';
      };
      configFile = mkOption {
        default = "/etc/borgmatic/config.yaml";
        type = types.path;
        description = mdDoc ''
          Borgmatic config file the exporter reads
          (matches services.borgmatic.settings output).
        '';
      };
    };

    postgresExporter = {
      enable = mkEnableOption "Enable Prometheus postgres exporter";
      port = mkOption {
        default = 9187;
        type = types.port;
        description = mdDoc ''
          The port for the postgres exporter to listen on.
        '';
      };
      dataSourceName = mkOption {
        default = "postgres://netdata@10.0.5.20:5432/postgres";
        type = types.str;
        description = mdDoc ''
          PostgreSQL DSN without password. Auth comes from PGPASSWORD in environmentFile.
        '';
      };
      environmentFile = mkOption {
        default = null;
        type = types.nullOr types.path;
        description = mdDoc ''
          Path to environment file with PGPASSWORD.
        '';
      };
    };

    nginxExporter = {
      enable = mkEnableOption "Enable Prometheus nginx exporter (needs services.nginx.statusPage)";
      port = mkOption {
        default = 9113;
        type = types.port;
        description = mdDoc ''
          The port for the nginx exporter to listen on.
        '';
      };
    };

    redisExporter = {
      enable = mkEnableOption "Enable Prometheus redis exporter";
      port = mkOption {
        default = 9121;
        type = types.port;
        description = mdDoc ''
          The port for the redis exporter to listen on.
        '';
      };
      passwordFile = mkOption {
        default = null;
        type = types.nullOr types.path;
        description = mdDoc ''
          File containing the redis password (passed as
          --redis.password-file). Needed when the server uses requirepass.
        '';
      };
    };

    postfixExporter = {
      enable = mkEnableOption "Enable Prometheus postfix exporter (reads the systemd journal)";
      port = mkOption {
        default = 9154;
        type = types.port;
        description = mdDoc ''
          The port for the postfix exporter to listen on.
        '';
      };
    };

    pveExporter = {
      enable = mkEnableOption "Enable Prometheus Proxmox VE exporter";

      pveServers = mkOption {
        default = [ ];
        type = types.listOf types.str;
        description = mdDoc ''
          Proxmox VE server addresses (hostnames or IPs).
        '';
      };

      environmentFile = mkOption {
        type = types.str;
        description = mdDoc ''
          Path to environment file with PVE credentials (PVE_USER, PVE_TOKEN_NAME, PVE_TOKEN_VALUE).
        '';
      };
    };

    scrapeConfigs = mkOption {
      default = [ ];
      type = types.listOf types.attrs;
      description = mdDoc ''
        Additional scrape configurations for Prometheus.
      '';
    };

    ruleFiles = mkOption {
      default = [ ];
      type = types.listOf types.path;
      description = mdDoc ''
        Additional alerting rule files for Prometheus.
      '';
    };

    lokiTargets = mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Loki instance name";
            };
            address = mkOption {
              type = types.str;
              description = "Loki IP address or hostname";
            };
            port = mkOption {
              type = types.port;
              default = 3030;
              description = "Loki metrics port";
            };
          };
        }
      );
      description = mdDoc ''
        Remote Loki instances to scrape metrics from.
      '';
    };

    gitlabRunners = mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "GitLab Runner name/identifier";
            };
            address = mkOption {
              type = types.str;
              description = "GitLab Runner IP address or hostname";
            };
            port = mkOption {
              type = types.port;
              default = 9252;
              description = "GitLab Runner metrics port";
            };
          };
        }
      );
      description = mdDoc ''
        GitLab Runner instances to scrape metrics from.
      '';
    };

    smartctlTargets = mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Smartctl exporter instance name";
            };
            address = mkOption {
              type = types.str;
              description = "Smartctl exporter IP address or hostname";
            };
            port = mkOption {
              type = types.port;
              default = 9633;
              description = "Smartctl exporter port";
            };
          };
        }
      );
      description = mdDoc ''
        Smartctl exporter instances to scrape metrics from.
      '';
    };

    borgmaticTargets = mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Borgmatic exporter instance name";
            };
            address = mkOption {
              type = types.str;
              description = "Borgmatic exporter IP address or hostname";
            };
            port = mkOption {
              type = types.port;
              default = 9996;
              description = "Borgmatic exporter port";
            };
          };
        }
      );
      description = mdDoc ''
        Borgmatic exporter instances to scrape metrics from.
      '';
    };

    tailscaleExporter = {
      enable = mkEnableOption "Enable Prometheus Tailscale exporter";

      port = mkOption {
        default = 9813;
        type = types.port;
        description = mdDoc ''
          The port for tailscale_exporter to listen on.
        '';
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/tailscale-exporter-env";
        description = mdDoc ''
          File to load as environment file. Must contain TAILSCALE_TAILNET,
          TAILSCALE_OAUTH_CLIENT_ID and TAILSCALE_OAUTH_CLIENT_SECRET
          (Tailscale admin console -> Settings -> OAuth clients, needs
          devices:read scope).
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--tailnet.example.com" ];
        description = mdDoc ''
          Extra flags to pass to the tailscale_exporter.
        '';
      };

      listenAddress = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = mdDoc ''
          Address to listen on for the tailscale exporter.
        '';
      };
    };

    cloudflareExporter = {
      enable = mkEnableOption "Enable the Cloudflare Prometheus exporter";

      port = mkOption {
        default = 9333;
        type = types.port;
        description = mdDoc ''
          The port for the Cloudflare exporter to listen on.
        '';
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/cloudflare-exporter-env";
        description = mdDoc ''
          File to load as environment file. Must contain CF_API_TOKEN and, for
          account-scoped tokens, CF_ACCOUNTS (comma delimited account ids).
        '';
      };

      extraFlags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "--cf_zones=zone1,zone2" ];
        description = mdDoc ''
          Extra flags to pass to the Cloudflare exporter, e.g. --cf_zones,
          --cf_exclude_zones, --free_tier or --scrape_interval.
        '';
      };
    };

    applicationTargets = mkOption {
      default = [ ];
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Application instance name";
            };
            address = mkOption {
              type = types.str;
              description = "Application IP address or hostname";
            };
            port = mkOption {
              type = types.port;
              description = "Application metrics port";
            };
            path = mkOption {
              type = types.str;
              default = "/metrics";
              description = "Metrics path";
            };
            scrapeInterval = mkOption {
              type = types.str;
              default = "";
              description = mdDoc "Scrape interval (e.g., '24h' for daily). Empty string uses Prometheus default.";
            };
          };
        }
      );
      description = mdDoc ''
        Application metrics endpoints to scrape.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.prometheus.enable) {
      services.prometheus = {
        inherit (cfg.prometheus) port;
        enable = true;
        retentionTime = cfg.prometheus.retentionTime;
        extraFlags = [
          "--query.max-samples=${toString cfg.prometheus.queryMaxSamples}"
        ]
        ++ lib.optional (
          cfg.prometheus.retentionSize != null
        ) "--storage.tsdb.retention.size=${cfg.prometheus.retentionSize}"
        ++ cfg.prometheus.extraFlags;
        exporters = {
          node = lib.mkIf cfg.prometheus.nodeExporter.enable {
            inherit (cfg.prometheus.nodeExporter) port;
            enabledCollectors = [
              "systemd"
              "processes"
              "cpufreq"
              "cpu"
              "filesystem"
              "hwmon"
              "textfile"
            ];
            extraFlags = [ "--collector.textfile.directory=${cfg.prometheus.nodeExporter.textfileDirectory}" ];
            enable = true;
          };
          tailscale = lib.mkIf cfg.prometheus.tailscaleExporter.enable {
            enable = true;
            inherit (cfg.prometheus.tailscaleExporter) port;
            inherit (cfg.prometheus.tailscaleExporter) environmentFile;
            inherit (cfg.prometheus.tailscaleExporter) extraFlags;
            inherit (cfg.prometheus.tailscaleExporter) listenAddress;
          };
          smartctl = lib.mkIf cfg.prometheus.smartctlExporter.enable {
            inherit (cfg.prometheus.smartctlExporter) port;
            enable = true;
          };
          borgmatic = lib.mkIf cfg.prometheus.borgmaticExporter.enable {
            inherit (cfg.prometheus.borgmaticExporter) port configFile;
            enable = true;
          };
          postgres = lib.mkIf cfg.prometheus.postgresExporter.enable {
            inherit (cfg.prometheus.postgresExporter) port dataSourceName environmentFile;
            enable = true;
          };
          nginx = lib.mkIf cfg.prometheus.nginxExporter.enable {
            inherit (cfg.prometheus.nginxExporter) port;
            enable = true;
          };
          redis = lib.mkIf cfg.prometheus.redisExporter.enable {
            inherit (cfg.prometheus.redisExporter) port;
            extraFlags = lib.optional (
              cfg.prometheus.redisExporter.passwordFile != null
            ) "--redis.password-file=${cfg.prometheus.redisExporter.passwordFile}";
            enable = true;
          };
          postfix = lib.mkIf cfg.prometheus.postfixExporter.enable {
            inherit (cfg.prometheus.postfixExporter) port;
            systemd.enable = true;
            enable = true;
          };
        };

        scrapeConfigs = [
          {
            job_name = "prometheus";
            static_configs = [
              {
                targets = [
                  "127.0.0.1:${toString cfg.prometheus.port}"
                ];
              }
            ];
          }
        ]
        ++ builtins.concatLists (
          map (loki: [
            {
              job_name = "loki-${loki.name}";
              static_configs = [
                {
                  targets = [ "${loki.address}:${toString loki.port}" ];
                  labels = { inherit (loki) name; };
                }
              ];
            }
          ]) cfg.prometheus.lokiTargets
        )
        ++ builtins.concatLists (
          map (runner: [
            {
              job_name = "gitlab-runner";
              static_configs = [
                {
                  targets = [ "${runner.address}:${toString runner.port}" ];
                  labels = {
                    runner_name = runner.name;
                  };
                }
              ];
              metrics_path = "/metrics";
              scrape_interval = "30s";
            }
          ]) cfg.prometheus.gitlabRunners
        )
        ++ builtins.concatLists (
          map (smartctl: [
            {
              job_name = "smartctl-${smartctl.name}";
              static_configs = [
                {
                  targets = [ "${smartctl.address}:${toString smartctl.port}" ];
                  labels = { inherit (smartctl) name; };
                }
              ];
            }
          ]) cfg.prometheus.smartctlTargets
        )
        ++ lib.optional (lib.length cfg.prometheus.borgmaticTargets > 0) {
          job_name = "borgmatic";
          static_configs = [
            {
              targets = map (
                borgmatic: "${borgmatic.address}:${toString borgmatic.port}"
              ) cfg.prometheus.borgmaticTargets;
            }
          ];
          metrics_path = "/metrics";
          scrape_interval = "1m";
        }
        ++ builtins.concatLists (
          map (app: [
            (
              if app.scrapeInterval != "" then
                {
                  job_name = "app-${app.name}";
                  static_configs = [
                    {
                      targets = [ "${app.address}:${toString app.port}" ];
                      labels = { inherit (app) name; };
                    }
                  ];
                  metrics_path = app.path;
                  scrape_interval = app.scrapeInterval;
                }
              else
                {
                  job_name = "app-${app.name}";
                  static_configs = [
                    {
                      targets = [ "${app.address}:${toString app.port}" ];
                      labels = { inherit (app) name; };
                    }
                  ];
                  metrics_path = app.path;
                }
            )
          ]) cfg.prometheus.applicationTargets
        )
        ++ lib.optional cfg.prometheus.tailscaleExporter.enable {
          job_name = "tailscale";
          static_configs = [
            {
              targets = [
                "${cfg.prometheus.tailscaleExporter.listenAddress}:${toString cfg.prometheus.tailscaleExporter.port}"
              ];
            }
          ];
        }
        ++ lib.optional cfg.prometheus.postgresExporter.enable {
          job_name = "postgres";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString cfg.prometheus.postgresExporter.port}"
              ];
            }
          ];
        }
        ++ lib.optional cfg.prometheus.cloudflareExporter.enable {
          job_name = "cloudflare";
          static_configs = [
            {
              targets = [
                "127.0.0.1:${toString cfg.prometheus.cloudflareExporter.port}"
              ];
            }
          ];
        }
        ++ cfg.prometheus.scrapeConfigs;

        ruleFiles = [
          defaultRules
          selfMonitoringRules
        ]
        ++ lib.optional (lib.length cfg.prometheus.smartctlTargets > 0) smartctlRules
        ++ lib.optional (lib.length cfg.prometheus.borgmaticTargets > 0) borgmaticRules
        ++ lib.optional cfg.prometheus.postgresExporter.enable postgresRules
        ++ lib.optional cfg.prometheus.nginxExporter.enable nginxRules
        ++ lib.optional cfg.prometheus.postfixExporter.enable mailRules
        ++ lib.optional cfg.prometheus.redisExporter.enable redisRules
        ++ cfg.prometheus.ruleFiles;
      };

      # No nixpkgs module for this one, so the unit is defined here
      systemd.services.cloudflare-exporter = lib.mkIf cfg.prometheus.cloudflareExporter.enable {
        description = "Prometheus Cloudflare exporter";
        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        serviceConfig = {
          EnvironmentFile = cfg.prometheus.cloudflareExporter.environmentFile;
          ExecStart = lib.escapeShellArgs (
            [
              (lib.getExe pkgs.prometheus-cloudflare-exporter)
              "--listen=127.0.0.1:${toString cfg.prometheus.cloudflareExporter.port}"
            ]
            ++ cfg.prometheus.cloudflareExporter.extraFlags
          );
          Restart = "on-failure";
          RestartSec = 30;
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts =
        lib.optional cfg.prometheus.nodeExporter.enable cfg.prometheus.nodeExporter.port
        ++ lib.optional cfg.prometheus.tailscaleExporter.enable cfg.prometheus.tailscaleExporter.port
        ++ lib.optional cfg.prometheus.smartctlExporter.enable cfg.prometheus.smartctlExporter.port
        ++ lib.optional cfg.prometheus.borgmaticExporter.enable cfg.prometheus.borgmaticExporter.port
        ++ lib.optional cfg.prometheus.nginxExporter.enable cfg.prometheus.nginxExporter.port
        ++ lib.optional cfg.prometheus.redisExporter.enable cfg.prometheus.redisExporter.port
        ++ lib.optional cfg.prometheus.postfixExporter.enable cfg.prometheus.postfixExporter.port;

      # Containers have no Tailnet interface; fellow containers reach
      # exporters over the container network (eth0 inside the container).
      networking.firewall.interfaces."eth0".allowedTCPPorts = lib.mkIf config.boot.isContainer (
        lib.optional cfg.prometheus.nodeExporter.enable cfg.prometheus.nodeExporter.port
        ++ lib.optional cfg.prometheus.smartctlExporter.enable cfg.prometheus.smartctlExporter.port
        ++ lib.optional cfg.prometheus.borgmaticExporter.enable cfg.prometheus.borgmaticExporter.port
        ++ lib.optional cfg.prometheus.nginxExporter.enable cfg.prometheus.nginxExporter.port
        ++ lib.optional cfg.prometheus.redisExporter.enable cfg.prometheus.redisExporter.port
        ++ lib.optional cfg.prometheus.postfixExporter.enable cfg.prometheus.postfixExporter.port
      );
    })

    (lib.mkIf (cfg.enable && cfg.prometheus.pveExporter.enable) {
      services.prometheus.exporters.pve = {
        enable = true;
        inherit (cfg.prometheus.pveExporter) environmentFile;
      };

      services.prometheus.scrapeConfigs = [
        {
          job_name = "pve";
          static_configs = [
            {
              targets = cfg.prometheus.pveExporter.pveServers;
            }
          ];
          metrics_path = "/pve";
          relabel_configs = [
            {
              source_labels = [ "__address__" ];
              target_label = "__param_target";
            }
            {
              source_labels = [ "__param_target" ];
              target_label = "instance";
            }
            {
              target_label = "__address__";
              replacement = "127.0.0.1:9221";
            }
          ];
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.prometheus.redisExporter.enable) {
      systemd.services.prometheus-redis-exporter.serviceConfig.DynamicUser = lib.mkForce false;
      users.users.redis-exporter = {
        isSystemUser = true;
        group = "redis-exporter";
      };
      users.groups.redis-exporter = { };
    })

    (lib.mkIf
      (
        cfg.enable
        && !cfg.prometheus.enable
        && (
          cfg.prometheus.nodeExporter.enable
          || cfg.prometheus.smartctlExporter.enable
          || cfg.prometheus.borgmaticExporter.enable
          || cfg.prometheus.nginxExporter.enable
          || cfg.prometheus.redisExporter.enable
          || cfg.prometheus.postfixExporter.enable
        )
      )
      {
        networking.firewall.interfaces.tailscale0.allowedTCPPorts =
          lib.optional cfg.prometheus.nodeExporter.enable cfg.prometheus.nodeExporter.port
          ++ lib.optional cfg.prometheus.smartctlExporter.enable cfg.prometheus.smartctlExporter.port
          ++ lib.optional cfg.prometheus.borgmaticExporter.enable cfg.prometheus.borgmaticExporter.port
          ++ lib.optional cfg.prometheus.nginxExporter.enable cfg.prometheus.nginxExporter.port
          ++ lib.optional cfg.prometheus.redisExporter.enable cfg.prometheus.redisExporter.port
          ++ lib.optional cfg.prometheus.postfixExporter.enable cfg.prometheus.postfixExporter.port;

        # Containers have no Tailnet interface: containers reach exporters over the container network (eth0 inside the container)
        networking.firewall.interfaces."eth0".allowedTCPPorts = lib.mkIf config.boot.isContainer (
          lib.optional cfg.prometheus.nodeExporter.enable cfg.prometheus.nodeExporter.port
          ++ lib.optional cfg.prometheus.smartctlExporter.enable cfg.prometheus.smartctlExporter.port
          ++ lib.optional cfg.prometheus.borgmaticExporter.enable cfg.prometheus.borgmaticExporter.port
          ++ lib.optional cfg.prometheus.nginxExporter.enable cfg.prometheus.nginxExporter.port
          ++ lib.optional cfg.prometheus.redisExporter.enable cfg.prometheus.redisExporter.port
          ++ lib.optional cfg.prometheus.postfixExporter.enable cfg.prometheus.postfixExporter.port
        );
        services.prometheus.exporters.node = lib.mkIf cfg.prometheus.nodeExporter.enable {
          inherit (cfg.prometheus.nodeExporter) port;
          enabledCollectors = [
            "systemd"
            "processes"
            "cpufreq"
            "cpu"
            "filesystem"
            "hwmon"
            "textfile"
          ];
          extraFlags = [ "--collector.textfile.directory=${cfg.prometheus.nodeExporter.textfileDirectory}" ];
          enable = true;
        };
        services.prometheus.exporters.smartctl = lib.mkIf cfg.prometheus.smartctlExporter.enable {
          inherit (cfg.prometheus.smartctlExporter) port;
          enable = true;
        };
        services.prometheus.exporters.borgmatic = lib.mkIf cfg.prometheus.borgmaticExporter.enable {
          inherit (cfg.prometheus.borgmaticExporter) port configFile;
          enable = true;
        };
        services.prometheus.exporters.nginx = lib.mkIf cfg.prometheus.nginxExporter.enable {
          inherit (cfg.prometheus.nginxExporter) port;
          enable = true;
        };
        services.prometheus.exporters.redis = lib.mkIf cfg.prometheus.redisExporter.enable {
          inherit (cfg.prometheus.redisExporter) port;
          extraFlags = lib.optional (
            cfg.prometheus.redisExporter.passwordFile != null
          ) "--redis.password-file=${cfg.prometheus.redisExporter.passwordFile}";
          enable = true;
        };
        services.prometheus.exporters.postfix = lib.mkIf cfg.prometheus.postfixExporter.enable {
          inherit (cfg.prometheus.postfixExporter) port;
          systemd.enable = true;
          enable = true;
        };
      }
    )
  ];
}
