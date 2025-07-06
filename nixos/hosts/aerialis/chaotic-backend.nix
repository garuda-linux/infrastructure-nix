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
    extraEnv = {
      "SSH_KEY" = config.sops.secrets."keypairs/chaotic/private".path;
    };
  };

  sops.secrets = {
    "compose/chaotic-backend" = { };
    "keypairs/chaotic/private" = { };
    "redis/chaotic" = { };
  };

  system.stateVersion = "25.05";
}
