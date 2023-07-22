{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # This container is just for docker-compose stuff
  services.docker-compose-runner.all-in-one = {
    envfile = garuda-lib.secrets.docker-compose.all-in-one;
    source = ./docker-compose/all-in-one;
  };

  # MongoDB port is being forwarded to this container
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  system.stateVersion = "23.05";
}
