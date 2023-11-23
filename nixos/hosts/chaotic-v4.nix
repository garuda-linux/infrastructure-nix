{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Redis is used to distribute build jobs
  services.redis = {
    vmOverCommit = true;
    servers."chaotic" = {
      bind = "127.0.0.1";
      enable = true;
      port = 6379;
      requirePassFile = "/var/garuda/secrets/chaotic/redis";
    };
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.chaotic-v4 = {
    envfile = garuda-lib.secrets.docker-compose.chaotic-v4;
    source = ../../docker-compose/chaotic-v4;
  };

  # Lock down chaotic-op group to SCP in landing zone
  services.openssh.extraConfig = ''
    Match Group chaotic-op
      ChrootDirectory /home/package-deployer/landing-zone
      ForceCommand internal-sftp
      AllowTcpForwarding no
      PermitOpen 127.0.0.1:6379
  '';

  # This container has a dedicated IP on the tailscale network
  # this way we can lock down access for nodes
  services.garuda-tailscale.enable = true;

  # Our package deploying users
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "chaotic-op" ];
    openssh.authorizedKeys.keys = [ "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN47/usTQsbmcAuG8CbEkurMDzQJxs+Tf8njI/4iTpKu" ];
  };
  users.groups.chaotic-op = { };

  system.stateVersion = "23.05";
}
