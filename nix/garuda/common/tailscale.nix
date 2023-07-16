{ config
, garuda-lib
, lib
, pkgs
, ...
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
      enable = true;
      useRoutingFeatures = lib.mkDefault "client";
    };

    # Autoconnect to our networks
    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";

      # Make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # Set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # Have the job run this shell script
      script = with pkgs; ''
        sleep 2
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then
          exit 0
        fi
        ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey} \
          --accept-routes
      '';
    };

    # Always allow traffic from Tailscale network
    networking.firewall.trustedInterfaces = [ "tailscale0" ];

    # Allow the Tailscale UDP port through the firewall
    networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  };
}

