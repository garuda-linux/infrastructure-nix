{ garuda-lib, ... }: {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-forum";
  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.70";
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
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-forum -p 666";
      };
      paths = [ "/var/discourse/shared/standalone/backups/" ];
      prune.keep = {
        within = "1d";
        daily = 3;
        weekly = 2;
        monthly = 1;
      };
      repo = "borg@89.58.13.188:.";
      startAt = "daily";
    };
  };

  # Enable Docker since we use the official Docker image in /var/discourse
  virtualisation.docker.enable = true;

  # Open required port
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
    allowedUDPPorts = [ 80 ];
  };

  system.stateVersion = "22.05";
}
