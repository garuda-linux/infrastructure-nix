{ config
, garuda-lib
, lib
, pkgs
, ...
}: {
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
      # Wait for tailscaled to settle
      sleep 2

      # Check if we are already authenticated to Tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # Otherwise authenticate with Tailscale
      ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey}
    '';
  };

  # Always allow traffic from Tailscale network
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Allow the Tailscale UDP port through the firewall
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
}
