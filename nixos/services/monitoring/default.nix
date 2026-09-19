{
  lib,
  ...
}:
{
  imports = [
    ./alertmanager.nix
    ./build-queue.nix
    ./grafana.nix
    ./prometheus.nix
    ./loki.nix
    ./fluent-bit.nix
    ./nixos-info.nix
  ];

  options.garuda.monitoring = with lib; {
    enable = mkEnableOption "Enable the monitoring stack";

    domain = mkOption {
      type = types.str;
      default = "grafana.garudalinux.net";
      description = mdDoc ''
        The domain for the monitoring stack.
      '';
    };

    baseDomain = mkOption {
      type = types.str;
      default = "garudalinux.net";
      description = mdDoc ''
        Base domain used to derive default hosts for the monitoring stack.
      '';
    };
  };
}
