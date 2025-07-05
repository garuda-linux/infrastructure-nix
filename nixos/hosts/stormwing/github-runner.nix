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

  # This container is just for docker-compose stuff
  garuda.services.compose-runner.github-runner = {
    envfile = "/var/garuda/secrets/github-runner.env";
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

  networking.firewall = {
    extraCommands = ''
      iptables -t nat -A PREROUTING -p tcp -d 172.17.0.1 --dport 3128 -j DNAT --to-destination 10.0.5.1:3128
      iptables -t nat -A POSTROUTING -p tcp -d 172.17.0.1 --dport 3128 -j SNAT --to-source 10.0.5.30
    '';
    extraStopCommands = ''
      iptables -t nat -D PREROUTING -p tcp -d 10.130.0.1 --dport 3128 -j DNAT --to-destination 10.0.5.1:3128
      iptables -t nat -D POSTROUTING -p tcp -d 10.0.5.1 --dport 3128 -j SNAT --to-source 10.0.5.130
    '';
  };

  system.stateVersion = "25.05";
}
