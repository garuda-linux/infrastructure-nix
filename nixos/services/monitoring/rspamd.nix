{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  cfg = config.garuda.monitoring;

  writer = pkgs.writeShellScript "rspamd-exporter" ''
    set -eu

    dir=${lib.escapeShellArg cfg.prometheus.nodeExporter.textfileDirectory}

    # Controller listens on a unix socket, not TCP.
    json="$(${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 10 \
      --unix-socket /run/rspamd/worker-controller.sock \
      -G --data-urlencode "password=$RSPAMD_PASSWORD" \
      http://localhost/stat || true)"
    [ -n "$json" ] || exit 0

    val() { ${pkgs.jq}/bin/jq -r "$1 // 0" <<<"$json"; }

    mkdir -p "$dir"
    tmp="$dir/rspamd.prom.tmp"

    {
      printf '# HELP rspamd_actions_reject Messages rejected.\n'
      printf '# TYPE rspamd_actions_reject counter\n'
      printf 'rspamd_actions_reject %s\n' "$(val '.actions["reject"]')"
      printf '# HELP rspamd_actions_soft_reject Messages soft rejected.\n'
      printf '# TYPE rspamd_actions_soft_reject counter\n'
      printf 'rspamd_actions_soft_reject %s\n' "$(val '.actions["soft reject"]')"
      printf '# HELP rspamd_actions_rewrite_subject Messages with rewritten subject.\n'
      printf '# TYPE rspamd_actions_rewrite_subject counter\n'
      printf 'rspamd_actions_rewrite_subject %s\n' "$(val '.actions["rewrite subject"]')"
      printf '# HELP rspamd_actions_add_header Messages with added header.\n'
      printf '# TYPE rspamd_actions_add_header counter\n'
      printf 'rspamd_actions_add_header %s\n' "$(val '.actions["add header"]')"
      printf '# HELP rspamd_actions_greylist Messages greylisted.\n'
      printf '# TYPE rspamd_actions_greylist counter\n'
      printf 'rspamd_actions_greylist %s\n' "$(val '.actions["greylist"]')"
      printf '# HELP rspamd_actions_no_action Messages with no action.\n'
      printf '# TYPE rspamd_actions_no_action counter\n'
      printf 'rspamd_actions_no_action %s\n' "$(val '.actions["no action"]')"
      printf '# HELP rspamd_stats_scanned Messages scanned.\n'
      printf '# TYPE rspamd_stats_scanned counter\n'
      printf 'rspamd_stats_scanned %s\n' "$(val '.scanned')"
      printf '# HELP rspamd_stats_learned Messages learned.\n'
      printf '# TYPE rspamd_stats_learned counter\n'
      printf 'rspamd_stats_learned %s\n' "$(val '.learned')"
      printf '# HELP rspamd_stats_spam_count Messages classified as spam.\n'
      printf '# TYPE rspamd_stats_spam_count counter\n'
      printf 'rspamd_stats_spam_count %s\n' "$(val '.spam_count')"
      printf '# HELP rspamd_stats_ham_count Messages classified as ham.\n'
      printf '# TYPE rspamd_stats_ham_count counter\n'
      printf 'rspamd_stats_ham_count %s\n' "$(val '.ham_count')"
      printf '# HELP rspamd_stats_connections Connections.\n'
      printf '# TYPE rspamd_stats_connections gauge\n'
      printf 'rspamd_stats_connections %s\n' "$(val '.connections')"
      printf '# HELP rspamd_stats_control_connections Control connections.\n'
      printf '# TYPE rspamd_stats_control_connections counter\n'
      printf 'rspamd_stats_control_connections %s\n' "$(val '.control_connections')"
      printf '# HELP rspamd_stats_pools_allocated Memory pools allocated.\n'
      printf '# TYPE rspamd_stats_pools_allocated counter\n'
      printf 'rspamd_stats_pools_allocated %s\n' "$(val '.pools_allocated')"
      printf '# HELP rspamd_stats_pools_freed Memory pools freed.\n'
      printf '# TYPE rspamd_stats_pools_freed counter\n'
      printf 'rspamd_stats_pools_freed %s\n' "$(val '.pools_freed')"
      printf '# HELP rspamd_stats_bytes_allocated Bytes allocated.\n'
      printf '# TYPE rspamd_stats_bytes_allocated counter\n'
      printf 'rspamd_stats_bytes_allocated %s\n' "$(val '.bytes_allocated')"
      printf '# HELP rspamd_stats_chunks_allocated Chunks allocated.\n'
      printf '# TYPE rspamd_stats_chunks_allocated counter\n'
      printf 'rspamd_stats_chunks_allocated %s\n' "$(val '.chunks_allocated')"
      printf '# HELP rspamd_stats_chunks_freed Chunks freed.\n'
      printf '# TYPE rspamd_stats_chunks_freed counter\n'
      printf 'rspamd_stats_chunks_freed %s\n' "$(val '.chunks_freed')"
      printf '# HELP rspamd_stats_chunks_oversized Oversized chunks.\n'
      printf '# TYPE rspamd_stats_chunks_oversized counter\n'
      printf 'rspamd_stats_chunks_oversized %s\n' "$(val '.chunks_oversized')"
      printf '# HELP rspamd_stats_fragmented Fragmented messages.\n'
      printf '# TYPE rspamd_stats_fragmented counter\n'
      printf 'rspamd_stats_fragmented %s\n' "$(val '.fragmented')"
      printf '# HELP rspamd_stats_total_learns Total learns.\n'
      printf '# TYPE rspamd_stats_total_learns counter\n'
      printf 'rspamd_stats_total_learns %s\n' "$(val '.total_learns')"
      printf '# HELP rspamd_stats_fuzzy Fuzzy hashes (rspamd.com store).\n'
      printf '# TYPE rspamd_stats_fuzzy gauge\n'
      printf 'rspamd_stats_fuzzy %s\n' "$(val '.fuzzy_hashes["rspamd.com"]')"
    } > "$tmp"

    ${pkgs.coreutils}/bin/mv -f "$tmp" "$dir/rspamd.prom"
  '';
in
{
  options.garuda.monitoring.rspamd = with lib; {
    enable = mkEnableOption "Scrape the local Rspamd controller stat into the node_exporter textfile";

    interval = mkOption {
      default = "60s";
      type = types.str;
      description = mdDoc ''
        How often the Rspamd controller is polled.
      '';
    };
  };

  config =
    lib.mkIf (cfg.enable && cfg.rspamd.enable && cfg.prometheus.nodeExporter.enable)
      {
        systemd.services.garuda-rspamd-exporter = {
          description = "Poll the Rspamd controller stat into the node_exporter textfile";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [
            "network-online.target"
            "rspamd.service"
          ];
          serviceConfig = {
            Type = "oneshot";
            EnvironmentFile = config.sops.templates."rspamd-env".path;
          };
          script = writer.outPath;
        };

        systemd.timers.garuda-rspamd-exporter = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = cfg.rspamd.interval;
          };
        };

        sops.secrets."mail/rspamd_controller" = { };
        sops.templates."rspamd-env" = {
          content = ''
            RSPAMD_PASSWORD=${config.sops.placeholder."mail/rspamd_controller"}
          '';
        };
      };
}
