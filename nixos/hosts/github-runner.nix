{ inputs
, keys
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
    inputs.hercules-ci-agent.nixosModules.agent-service
  ];

  # Common Docker configurations
  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
    package = pkgs.docker_24; # Until the man pages are fixed in pkgs.docker
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.github-runner = {
    args = "run github-runner";
    envfile = "/var/garuda/secrets/github-runner.env";
    source = ../../docker-compose/github-runner;
  };

  # Test out Hercules CI for deployments
  services.hercules-ci-agent.enable = true;
  services.hercules-ci-agent.settings.concurrentTasks = 10;

  # Enable SSH
  services.openssh.enable = true;

  # No custom users - oonly Pedro and root via nixos-container root-login
  users.allowNoPasswordLogin = true;
  users.mutableUsers = false;
  users.users.pedrohlc = {
    home = "/home/pedrohlc";
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ keys.pedrohlc ];
  };

  # Make Pedro god here
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
    enableUserServices = true;
  };

  system.stateVersion = "23.05";
}
