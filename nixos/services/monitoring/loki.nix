{
  config,
  lib,
  ...
}:
let
  cfg = config.garuda.monitoring;
in
{
  options.garuda.monitoring.loki = with lib; {
    enable = mkEnableOption "Enable Loki";

    port = mkOption {
      default = 3030;
      type = types.port;
      description = mdDoc ''
        The port for Loki to listen on.
      '';
    };

    dataDir = mkOption {
      default = "/var/lib/loki";
      type = types.str;
      description = mdDoc ''
        The directory for Loki data.
      '';
    };

    retentionPeriod = mkOption {
      default = "744h";
      type = types.str;
      description = mdDoc ''
        How long to keep logs before the compactor deletes them.
        Loki duration string, e.g. "744h" (31 days).
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.loki.enable) {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = cfg.loki.port;
        };

        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore = {
              store = "inmemory";
            };
          };
          replication_factor = 1;
          path_prefix = cfg.loki.dataDir;
        };

        limits_config = {
          retention_period = cfg.loki.retentionPeriod;
          allow_structured_metadata = true;
          reject_old_samples = true;
          reject_old_samples_max_age = "168h";
          ingestion_rate_mb = 16;
          ingestion_burst_size_mb = 32;
          per_stream_rate_limit = "3MB";
          per_stream_rate_limit_burst = "15MB";
          max_global_streams_per_user = 10000;
          max_query_series = 1000;
          max_entries_limit_per_query = 5000;
          max_label_names_per_series = 15;
        };

        compactor = {
          working_directory = "${cfg.loki.dataDir}/compactor";
          compaction_interval = "10m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          retention_delete_worker_count = 150;
          delete_request_store = "filesystem";
        };

        schema_config = {
          configs = [
            {
              from = "2020-05-15";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };

        storage_config = {
          filesystem = {
            directory = "${cfg.loki.dataDir}/chunks";
          };
        };
      };
    };

    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.loki.port ];
  };
}
