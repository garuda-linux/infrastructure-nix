{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg = config.garuda.monitoring;

  nixosRevision =
    if config.system.nixos.revision == null then
      "unknown"
    else
      config.system.nixos.revision;

  configuration =
    if config.system.configurationRevision == null then
      "unknown"
    else
      config.system.configurationRevision;

  dirty =
    if lib.hasSuffix "-dirty" configuration then
      "true"
    else
      "false";

  infoContent = ''
    # HELP nixos_info NixOS release, version and configuration revision.
    # TYPE nixos_info gauge
    nixos_info{release="${config.system.nixos.release}",version="${config.system.nixos.version}",revision="${nixosRevision}",configuration="${configuration}",dirty="${dirty}"} 1
    # HELP nixos_build_timestamp_seconds Unix timestamp of the currently active system generation.
    # TYPE nixos_build_timestamp_seconds gauge
  '';

  writer = pkgs.writeShellScript "write-nixos-info" ''
    set -eu
    dir="${cfg.prometheus.nodeExporter.textfileDirectory}"
    mkdir -p "$dir"
    printf '%s' ${lib.escapeShellArg infoContent} > "$dir/nixos_info.prom.tmp"
    ts="$(${pkgs.coreutils}/bin/stat -c %Y /run/current-system 2>/dev/null || ${pkgs.coreutils}/bin/date +%s)"
    printf 'nixos_build_timestamp_seconds %s\n' "$ts" >> "$dir/nixos_info.prom.tmp"
    ${pkgs.coreutils}/bin/mv "$dir/nixos_info.prom.tmp" "$dir/nixos_info.prom"
  '';
in
{
  options.garuda.monitoring.hostInfo = with lib; {
    enable = mkEnableOption "Write NixOS version and revision to the node_exporter textfile";
  };

  config = lib.mkIf (cfg.hostInfo.enable && cfg.prometheus.nodeExporter.enable) {
    system.configurationRevision = lib.mkDefault (self.rev or self.dirtyRev or null);

    system.activationScripts.nixos-info = {
      text = writer.outPath;
      deps = [ ];
    };

    systemd.services.garuda-nixos-info = {
      description = "Write NixOS version and revision to node_exporter textfile";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-tmpfiles-setup.service" ];
      before = [ "prometheus-node-exporter.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = writer.outPath;
    };
  };
}
