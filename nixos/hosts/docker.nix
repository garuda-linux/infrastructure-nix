{ sources, ... }: {
  imports = sources.defaultModules ++ [
    ../modules
    ./docker/docker-compose.nix
  ];

  system.stateVersion = "23.05";
}
