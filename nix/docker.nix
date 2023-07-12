{ garuda-lib, lib, sources, ... }: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  networking.hostName = "docker";

  # This container is just for docker-compose stuff
  services.docker-compose-runner.all-in-one = {
    envfile = garuda-lib.secrets.docker-compose.all-in-one;
    source = ./docker-compose/all-in-one;
  };

  system.stateVersion = "23.05";
}
