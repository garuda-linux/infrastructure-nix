{
  config,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  # This container is just for compose stuff
  garuda.services.compose-runner.docker = {
    envfile = config.sops.secrets."compose/docker".path;
    source = ../../../compose/docker;
  };

  sops.secrets = {
    "compose/docker" = {
      neededForUsers = true;
      restartUnits = [ "compose-runner-docker.service" ];
    };
    "compose/matterbridge" = {
      path = "/var/garuda/secrets/compose/matterbridge.toml";
      mode = "0600";
      neededForUsers = true;
      owner = "1001";
      group = "1001";
      restartUnits = [ "compose-runner-docker.service" ];
    };
  };

  system.stateVersion = "25.05";
}
