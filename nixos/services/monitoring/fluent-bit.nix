{
  config,
  lib,
  ...
}:
let
  cfg = config.garuda.monitoring;

  defaultSystemdUnits = [
    "sshd.service"
    "systemd-journald.service"
  ]
  ++ lib.optional (config.services.borgmatic.enable or false) "borgmatic.service";

  journalLokiOutput = match: {
    name = "loki";
    inherit match;
    host = cfg.fluent-bit.lokiAddress;
    port = cfg.fluent-bit.lokiPort;
    labels = "service=\$systemd_unit,host=\$hostname";
    tenant_id = "garuda";
    drop_single_key = "on";
    line_format = "json";
    structured_metadata = "detected_level=\$detected_level";
  };
in
{
  options.garuda.monitoring.fluent-bit = with lib; {
    enable = mkEnableOption "Enable Fluent Bit for log collection to Loki";

    lokiAddress = mkOption {
      default = "";
      type = types.str;
      description = mdDoc ''
        The address of the Loki frontend (via Tailscale).
      '';
    };

    lokiPort = mkOption {
      default = 3100;
      type = types.port;
      description = mdDoc ''
        The port of the Loki frontend.
      '';
    };

    systemdUnits = mkOption {
      default = defaultSystemdUnits;
      type = types.listOf types.str;
      description = mdDoc ''
        Systemd units to collect logs from. Automatically includes common services
        based on what's enabled (borgmatic, docker).
        Add host-specific services using extraSystemdUnits.
      '';
    };

    extraSystemdUnits = mkOption {
      default = [ ];
      type = types.listOf types.str;
      description = mdDoc ''
        Additional systemd units to collect logs from. These are appended to
        the automatically-detected services.
      '';
    };

    dockerLoggingDriver = mkOption {
      default = false;
      type = types.bool;
      description = mdDoc ''
        Enable Fluent Bit as a Docker logging driver. This adds a forward input
        plugin listening on port 24224 for Docker container logs.
        Configure Docker daemon with:
        { "log-driver": "fluentd", "log-opts": { "fluentd-address": "127.0.0.1:24224" } }
      '';
    };

    nginxAccessLog = {
      enable = mkEnableOption "Ship Nginx JSON access logs to Loki via a tail input";
      hostLabel = mkOption {
        type = types.str;
        default = "";
        description = mdDoc ''
          Value of the `host` label for Nginx access logs.
          Defaults to networking.hostName when empty.
        '';
      };
    };
  };

  config = lib.mkIf (cfg.enable && cfg.fluent-bit.enable) (
    lib.mkMerge [
      {
        services.fluent-bit = {
          enable = true;
          settings = {
            service = {
              Flush = 1;
              Daemon = false;
              Log_Level = "info";
            };

            parsers = lib.optional cfg.fluent-bit.nginxAccessLog.enable {
              name = "nginx_access";
              format = "json";
            };

            pipeline = {
              inputs = [
                {
                  name = "systemd";
                  tag = "host.*";
                  read_from_tail = true;
                  strip_underscores = true;
                  lowercase = true;
                  systemd_filter = map (unit: "_SYSTEMD_UNIT=${unit}") (
                    cfg.fluent-bit.systemdUnits ++ cfg.fluent-bit.extraSystemdUnits
                  );
                  systemd_filter_type = "or";
                }
              ]
              ++ lib.optional cfg.fluent-bit.dockerLoggingDriver {
                name = "forward";
                tag = "docker.*";
                listen = "127.0.0.1";
                port = 24224;
              }
              ++ lib.optional cfg.fluent-bit.nginxAccessLog.enable {
                name = "tail";
                tag = "nginx.access";
                path = "/var/log/nginx/access.log";
                parser = "nginx_access";
                db = "/tmp/fluent-bit-nginx-access.db";
                mem_buf_limit = "5MB";
                skip_long_lines = "On";
                rotate_wait = 5;
                refresh_interval = 5;
              };

              filters = [
                # Strip ANSI escapes and derive `detected_level` before any other filter runs
                {
                  name = "lua";
                  match = "*";
                  script = ./fluent-bit-level.lua;
                  call = "process";
                }
                {
                  name = "grep";
                  match = "*";
                  logical_op = "or";
                  exclude = "$message level=(info|debug)";
                }
              ];

              outputs = [
                (journalLokiOutput "host.*")
              ]
              ++ lib.optional cfg.fluent-bit.dockerLoggingDriver (journalLokiOutput "docker.*")
              ++ lib.optional cfg.fluent-bit.nginxAccessLog.enable {
                name = "loki";
                match = "nginx.*";
                host = cfg.fluent-bit.lokiAddress;
                port = cfg.fluent-bit.lokiPort;
                labels = "service=nginx-access,host=${
                  if cfg.fluent-bit.nginxAccessLog.hostLabel != "" then
                    cfg.fluent-bit.nginxAccessLog.hostLabel
                  else
                    config.networking.hostName
                },vhost=\$host";
                tenant_id = "garuda";
                line_format = "json";
                structured_metadata = "status=\$status,country=\$cf_country,lat=\$cf_lat,lon=\$cf_lon,req_time=\$req_time";
              };
            };
          };
        };
      }
      (lib.mkIf cfg.fluent-bit.nginxAccessLog.enable {
        systemd.services.fluent-bit.serviceConfig.SupplementaryGroups = [
          "systemd-journal"
          "nginx"
        ];
      })
    ]
  );
}
