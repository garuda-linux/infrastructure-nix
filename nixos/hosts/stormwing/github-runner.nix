{
  keys,
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

  # This container is just for compose stuff
  garuda.services.compose-runner.github-runner = {
    envfile = "/var/.github-runner.env";
    source = ../../../compose/github-runner;
  };
  garuda.services.compose-runner.gitlab-runner = {
    source = ../../../compose/gitlab-runner;
  };

  # Enable SSH
  services.openssh.enable = true;

  # No custom users - only Pedro and root via nixos-container root-login
  users = {
    allowNoPasswordLogin = true;
    mutableUsers = false;
    users.pedrohlc = {
      home = "/home/pedrohlc";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.pedrohlc ];
    };
  };

  # Make Pedro god here
  nix.settings.trusted-users = [ "pedrohlc" ];
  security.sudo.extraRules = [
    {
      users = [ "pedrohlc" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # OOM prevention
  systemd.oomd = {
    enable = true; # This is actually the default, anyways...
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  system.stateVersion = "25.05";
}
