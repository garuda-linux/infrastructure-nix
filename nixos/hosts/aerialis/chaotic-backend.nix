{
  config,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [
    ../../modules
    ../../modules/special/ssh-allow-chaotic.nix
  ];

  garuda.services.compose-runner.chaotic-backend = {
    envfile = config.sops.secrets."compose/chaotic-backend".path;
    source = ../../../compose/chaotic-backend;
  };

  # Redis is used to distribute build jobs
  services.redis = {
    vmOverCommit = true;
    servers."chaotic" = {
      bind = null;
      enable = true;
      port = 6379;
      requirePassFile = config.sops.secrets."redis/chaotic".path;
    };
  };


  sops.secrets = {
    "compose/chaotic-backend" = { };
    "redis/chaotic" = { };
  };

  system.stateVersion = "25.05";
}
