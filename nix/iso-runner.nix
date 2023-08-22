{ garuda-lib
, lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # This container is just for docker-compose stuff
  services.docker-compose-runner.iso-runner = {
    envfile = garuda-lib.secrets.docker-compose.iso-runner;
    source = ./docker-compose/runner;
  };

  # Lets build Garuda ISO here, serving is done via
  # Temeraire already 
  services = {
    garuda-iso.enable = true;
    nginx.enable = lib.mkForce false;
    rsyncd.enable = lib.mkForce false;
  };

  system.stateVersion = "23.05";
}
