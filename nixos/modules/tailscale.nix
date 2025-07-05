{
  config,
  lib,
  ...
}:
let
  cfg = config.services.garuda-tailscale;
in
{
  options.services.garuda-tailscale = {
    enable = lib.mkOption {
      default = false;
      description = "Enables the Tailscale service and connects to our Tailnet.";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable the Tailscale service
    services.tailscale = {
      authKeyFile = config.sops.secrets."tailscale/authkey".path;
      enable = true;
      extraUpFlags = [
        "--ssh"
        "--accept-routes"
      ];
      openFirewall = true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    # Always allow traffic from Tailscale network
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    sops.secrets."tailscale/authkey" = { };
  };
}
