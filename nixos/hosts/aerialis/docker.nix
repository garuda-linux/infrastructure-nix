{
  config,
  garuda-lib,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda =
    garuda-lib.mkMonitoring {
      host = "aerialis";
      units = [
        "compose-runner-docker.service"
        "docker.service"
      ];
    }
    // {
      services.compose-runner.docker = {
        envfile = config.sops.secrets."compose/docker".path;
        source = ../../../compose/docker;
        extraEnv = {
          "MATTERBRIDGE_CONFIG" = config.sops.secrets."compose/matterbridge".path;
        };
      };
    };

  sops.secrets = {
    "compose/docker" = {
      restartUnits = [ "compose-runner-docker.service" ];
    };
    "compose/matterbridge" = {
      restartUnits = [ "compose-runner-docker.service" ];
    };
  };

  system.stateVersion = "25.05";
}
