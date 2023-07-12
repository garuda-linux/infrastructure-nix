{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Avoid running Netdata instances in containers
  services.garuda-monitoring.enable = lib.mkForce false;

  # Enable Docker since we use the official Docker image in /var/discourse
  virtualisation.docker.enable = true;

  # Open required port
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
    allowedUDPPorts = [ 80 ];
  };

  system.stateVersion = "23.05";
}

