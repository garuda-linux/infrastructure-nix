{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Redis is used to distribute build jobs
  services.redis = {
    vmOverCommit = true;
    servers."chaotic" = {
      bind = "0.0.0.0"; # TODO: restrict to tailscale IP?
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

  # This container has a dedicated IP on the tailscale network
  # this way we can lock down access for nodes
  services.garuda-tailscale.enable = true;

  # Our package deploying users
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "chaotic-op" ];
    openssh.authorizedKeys.keys = [ "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p" ];
  };
  users.groups.chaotic-op = { };

  system.stateVersion = "23.05";
}
