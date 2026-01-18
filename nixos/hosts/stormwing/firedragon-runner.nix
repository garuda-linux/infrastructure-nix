{
  keys,
  sources,
  ...
}:
{
  # No default modules, untrusted container!
  # imports = sources.defaultModules ++ [
  #   ./garuda/garuda.nix
  # ];

  imports = [
    ../../modules/hardening.nix
    ../../modules/motd.nix
    ../../services/compose-runner/compose-runner.nix
  ];

  # Common Docker configurations
  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
  };

  # GitLab runners
  garuda.services.compose-runner.firedragon-runner = {
    source = ../../../compose/firedragon-runner;
  };

  # Enable SSH
  services.openssh.enable = true;

  # No custom users - only Stefan and root via nixos-container root-login
  users = {
    allowNoPasswordLogin = true;
    mutableUsers = false;
    users.stefan = {
      home = "/home/stefan";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.stefan ];
    };
  };

  nix.settings.trusted-users = [ "stefan" ];
  security.sudo.extraRules = [
    {
      users = [ "stefan" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  systemd.oomd = {
    enable = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  system.stateVersion = "25.05";
}
