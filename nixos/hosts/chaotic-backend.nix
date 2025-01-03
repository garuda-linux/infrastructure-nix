{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  services.docker-compose-runner.chaotic-backend = {
    envfile = garuda-lib.secrets.docker-compose.chaotic-backend;
    source = ../../docker-compose/chaotic-backend;
  };

  system.stateVersion = "25.05";
}
