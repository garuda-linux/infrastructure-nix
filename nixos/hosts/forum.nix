{ sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../garuda/garuda.nix
  ];

  # Enable Docker since we use the official Docker image in /var/discourse
  virtualisation.docker.enable = true;

  # Open required port
  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "23.05";
}

