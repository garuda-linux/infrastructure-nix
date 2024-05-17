{ garuda-lib
, sources
, pkgs
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules "${sources.chaotic-portable-builder}/nix/nixos.nix" ];

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
      AllowTCPForwarding yes
      AllowAgentForwarding no
      X11Forwarding no
      PermitTunnel no
      ForceCommand internal-sftp
      PermitOpen 127.0.0.1:6379
  '';

  # Our package deploying users
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "chaotic-op" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN47/usTQsbmcAuG8CbEkurMDzQJxs+Tf8njI/4iTpKu"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDD2ulefvEwwft9gXj2oUgRl0zWKjG2wkg4xHP1F2p8I" # garuda-build
    ];
  };
  users.groups.chaotic-op = { };

  # Expose raw /proc for podman
  systemd.services.expose-raw-proc = {
    description = "Expose clean /proc for podman";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /tmp/raw_proc
      ${pkgs.mount}/bin/mount --bind /proc /tmp/raw_proc
    '';
  };

  networking.firewall.allowedTCPPorts = [ 8080 ];

  # Enable the user accounts of chaotic maintainers
  garuda-lib.chaoticUsers = true;

  # Workaround massive storage leaks due to docker-export folders
  # TODO: find out whats going on here
  systemd.services.docker-cleanup = {
    description = "Cleanup docker-export folders periodically";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        set -e
        find /var/lib/docker/tmp  -maxdepth 1 -mmin +30 -exec rm -rf {} \;
      '';
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.docker-cleanup = {
    description = "Cleanup docker-export folders periodically";
    timerConfig.OnCalendar = [ "*:0/30" ];
    wantedBy = [ "timers.target" ];
  };

  system.stateVersion = "23.05";
}
