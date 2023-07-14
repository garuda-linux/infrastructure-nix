{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # This container is just for docker-compose stuff
  services.docker-compose-runner.runner = {
    envfile = garuda-lib.secrets.docker-compose.runner;
    source = ./docker-compose/runner;
  };

  # Lets build Garuda isos here, too
  services.garuda-iso.enable = true;

  system.stateVersion = "23.05";
}
