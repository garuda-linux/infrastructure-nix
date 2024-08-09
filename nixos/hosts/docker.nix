{ sources, ... }: {
  imports = sources.defaultModules ++ [
    ../modules
    ./docker/docker-compose.nix
  ];

  # MongoDB port is being forwarded to this container
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  system.stateVersion = "23.05";
}
