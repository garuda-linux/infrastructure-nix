{ ... }: {
  # No default modules, untrusted container!
  # imports = sources.defaultModules ++ [
  #   ./garuda/garuda.nix
  # ];

  imports = [
    ../services/docker-compose-runner/docker-compose-runner.nix
  ];

  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.iso-runner = {
    args = "run github-runner";
    envfile = "/var/garuda/secrets/github-runner.env";
    source = ./docker-compose/github-runner;
  };

  system.stateVersion = "23.05";
}
