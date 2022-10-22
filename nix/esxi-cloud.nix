{ garuda-lib, ... }: {
  imports = [ ./garuda/garuda.nix ./hardware-configuration.nix ./garuda/common/esxi.nix ];

  # Base configuration
  networking.hostName = "esxi-cloud";
  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.40";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Configure backups to backup-dragon
  services.borgbackup.jobs = {
    backupToBackupDragon = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-cloud -p 666";
      };
      paths = [ "/var/garuda/docker-compose-runner/esxi-cloud" ];
      prune.keep = {
        within = "1d";
        daily = 7;
        weekly = 2;
        monthly = 1;
      };
      repo = "borg@89.58.13.188:.";
      startAt = "daily";
    };
  };

  # Enable our docker-compose stack
  services.docker-compose-runner.esxi-cloud = {
    source = ./docker-compose/esxi-cloud;
    envfile = garuda-lib.secrets.docker-compose.esxi-cloud;
  };

  # Open required port
  networking.firewall = {
    allowedTCPPorts = [ 443 ];
    allowedUDPPorts = [ 443 ];
  };

  system.stateVersion = "22.05";
}
