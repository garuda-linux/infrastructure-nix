{
  config,
  garuda-lib,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [
    ../../modules
    ../../modules/special/ssh-allow-chaotic.nix
  ];

  garuda =
    garuda-lib.mkMonitoring {
      host = "aerialis";
      units = [
        "compose-runner-chaotic-backend.service"
        "docker.service"
        "redis-chaotic.service"
      ];
      exporters = [ "redisExporter" ];
      extraPrometheus.redisExporter.passwordFile = config.sops.secrets."redis/exporter".path;
    }
    // {
      services.compose-runner.chaotic-backend = {
        envfile = config.sops.secrets."compose/chaotic-backend".path;
        source = ../../../compose/chaotic-backend;
        extraEnv = {
          "SSH_KEY" = config.sops.secrets."keypairs/chaotic/private".path;
        };
      };
    };

  services.redis = {
    servers."chaotic" = {
      enable = true;
      port = 6379;
      requirePassFile = config.sops.secrets."redis/chaotic".path;
      save = [
        [
          20
          1
        ]
      ];
    };
  };

  sops.secrets =
    garuda-lib.mkSecrets [
      "compose/chaotic-backend"
      "keypairs/chaotic/private"
      "redis/chaotic"
    ]
    // {
      "redis/exporter" = {
        owner = "redis-exporter";
        group = "redis-exporter";
        mode = "0400";
      };
    };

  system.stateVersion = "25.05";
}
