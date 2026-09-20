{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.monitoring;

  writer = pkgs.writeShellScript "build-queue-exporter" ''
    set -eu

    dir=${lib.escapeShellArg cfg.prometheus.nodeExporter.textfileDirectory}
    url=${lib.escapeShellArg cfg.buildQueue.url}

    json="$(${pkgs.curl}/bin/curl --fail --silent --show-error --max-time 30 "$url")"

    mkdir -p "$dir"
    tmp="$dir/build_queue.prom.tmp"

    {
      printf '# HELP build_queue_active Packages currently being built.\n'
      printf '# TYPE build_queue_active gauge\n'
      printf 'build_queue_active %s\n' "$(${pkgs.jq}/bin/jq -r '.active.count // 0' <<<"$json")"

      printf '# HELP build_queue_waiting Packages waiting to be built.\n'
      printf '# TYPE build_queue_waiting gauge\n'
      printf 'build_queue_waiting %s\n' "$(${pkgs.jq}/bin/jq -r '.waiting.count // 0' <<<"$json")"

      printf '# HELP build_queue_idle Idle build nodes.\n'
      printf '# TYPE build_queue_idle gauge\n'
      printf 'build_queue_idle %s\n' "$(${pkgs.jq}/bin/jq -r '.idle.count // 0' <<<"$json")"

      printf '# HELP build_queue_builders Build nodes by build class and state.\n'
      printf '# TYPE build_queue_builders gauge\n'
      ${pkgs.jq}/bin/jq -r '
        ([ (.idle.nodes // [])[] | { class: (.build_class | tostring), state: "idle" } ]
        + [ (.active.packages // [])[] | { class: (.build_class | tostring), state: "active" } ])
        | group_by([.class, .state])
        | .[] | "build_queue_builders{build_class=\"\(.[0].class)\",state=\"\(.[0].state)\"} \(length)"
      ' <<<"$json"

      printf '# HELP build_queue_builder_info Build nodes by name, class and state.\n'
      printf '# TYPE build_queue_builder_info gauge\n'
      ${pkgs.jq}/bin/jq -r '
        ([ (.idle.nodes // [])[]
           | { builder: ((.name // "unknown") | tostring | gsub("[\"\\\\\n]"; "")),
               raw_class: ((.build_class // "unknown") | tostring),
               state: "idle" } ]
        + [ (.active.packages // [])[]
            | { builder: ((.node // "unknown") | tostring | gsub("[\"\\\\\n]"; "")),
                raw_class: ((.build_class // "unknown") | tostring),
                state: "active" } ])
        | map((.class = (if .raw_class == "unknown" then .builder else .raw_class end)) | del(.raw_class))
        | unique
        | .[] | "build_queue_builder_info{builder=\"\(.builder)\",build_class=\"\(.class)\",state=\"\(.state)\"} 1"
      ' <<<"$json"

      printf '# HELP build_queue_active_package_info Packages building, by package and builder.\n'
      printf '# TYPE build_queue_active_package_info gauge\n'
      ${pkgs.jq}/bin/jq -r '
        [ (.active.packages // [])[]
          | { package: ((.name // "unknown") | tostring | gsub("[\"\\\\\n]"; "")),
              builder: ((.node // "unknown") | tostring | gsub("[\"\\\\\n]"; "")),
              class: ((.build_class // "unknown") | tostring) } ]
        | .[] | "build_queue_active_package_info{package=\"\(.package)\",builder=\"\(.builder)\",build_class=\"\(.class)\"} 1"
      ' <<<"$json"

      printf '# HELP build_queue_waiting_package_info Packages waiting, by package.\n'
      printf '# TYPE build_queue_waiting_package_info gauge\n'
      ${pkgs.jq}/bin/jq -r '
        [ (.waiting.packages // [])[]
          | { package: ((.name // "unknown") | tostring | gsub("[\"\\\\\n]"; "")),
              class: ((.build_class // "unknown") | tostring) } ]
        | .[] | "build_queue_waiting_package_info{package=\"\(.package)\",build_class=\"\(.class)\"} 1"
      ' <<<"$json"

      printf '# HELP build_queue_waiting_by_class Packages waiting, by build class.\n'
      printf '# TYPE build_queue_waiting_by_class gauge\n'
      ${pkgs.jq}/bin/jq -r '
        [ (.waiting.packages // [])[] | ((.build_class // "unknown") | tostring) ]
        | group_by(.)
        | .[] | "build_queue_waiting_by_class{build_class=\"\(.[0])\"} \(length)"
      ' <<<"$json"

      printf '# HELP build_queue_active_by_class Packages building, by build class.\n'
      printf '# TYPE build_queue_active_by_class gauge\n'
      ${pkgs.jq}/bin/jq -r '
        [ (.active.packages // [])[] | ((.build_class // "unknown") | tostring) ]
        | group_by(.)
        | .[] | "build_queue_active_by_class{build_class=\"\(.[0])\"} \(length)"
      ' <<<"$json"
    } > "$tmp"

    ${pkgs.coreutils}/bin/mv -f "$tmp" "$dir/build_queue.prom"
  '';
in
{
  options.garuda.monitoring.buildQueue = with lib; {
    enable = mkEnableOption "Poll the Chaotic build queue and expose its stats through node_exporter";

    url = mkOption {
      default = "https://builds.garudalinux.org/api/queue/stats";
      type = types.str;
      description = mdDoc ''
        Build queue stats endpoint to poll.
      '';
    };

    interval = mkOption {
      default = "30s";
      type = types.str;
      description = mdDoc ''
        How often the queue stats endpoint is polled.
      '';
    };
  };

  config = lib.mkIf (cfg.enable && cfg.buildQueue.enable && cfg.prometheus.nodeExporter.enable) {
    systemd.services.garuda-build-queue-exporter = {
      description = "Poll the Chaotic build queue into the node_exporter textfile";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig.Type = "oneshot";
      script = writer.outPath;
    };

    systemd.timers.garuda-build-queue-exporter = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = cfg.buildQueue.interval;
      };
    };
  };
}
