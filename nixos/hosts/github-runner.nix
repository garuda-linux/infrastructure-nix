{ keys
, pkgs
, ...
}: {
  # No default modules, untrusted container!
  # imports = sources.defaultModules ++ [
  #   ./garuda/garuda.nix
  # ];

  imports = [
    ../modules/hardening.nix
    ../modules/motd.nix
    ../services/docker-compose-runner/docker-compose-runner.nix
  ];

  # Common Docker configurations
  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
    package = pkgs.docker_24; # Until the man pages are fixed in pkgs.docker
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.github-runner = {
    envfile = "/var/garuda/secrets/github-runner.env";
    source = ../../docker-compose/github-runner;
  };
  services.docker-compose-runner.gitlab-runner = {
    source = ../../docker-compose/gitlab-runner;
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

  system.stateVersion = "23.05";
}
