{
  config,
  pkgs,
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
    extraEnv = {
      "SSH_KEY" = config.sops.secrets."keypairs/chaotic/private".path;
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

  sops.secrets = {
    "compose/chaotic-backend" = { };
    "keypairs/chaotic/private" = { };
    "redis/chaotic" = { };
  };

  system.stateVersion = "25.05";
}
