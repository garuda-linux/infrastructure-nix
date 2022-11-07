{ garuda-lib, lib, sources, pkgs, ... }: {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-web-two";
  networking.interfaces.ens192.ipv4.addresses = [{
    address = "192.168.1.50";
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
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-web-two -p 666";
      };
      paths = [
        "/var/garuda/backups/postgres"
        "/var/garuda/docker-compose-runner/esxi-web-two"
      ];
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
  services.docker-compose-runner.esxi-web-two = {
    source = ./docker-compose/esxi-web-two;
    envfile = garuda-lib.secrets.docker-compose.esxi-web-two;
  };

  # Our Postgres database
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "meshcentral" "wikijs" "synapse" "matrix-telegram" "matrix-discord" "matrix-irc" ];
    ensureUsers = [
      {
        name = "synapse";
        ensurePermissions = { "DATABASE synapse" = "ALL PRIVILEGES"; };
      }
      {
        name = "matrix-bridges";
        ensurePermissions = {
          "DATABASE \"matrix-telegram\"" = "ALL PRIVILEGES";
          "DATABASE \"matrix-discord\"" = "ALL PRIVILEGES";
          "DATABASE \"matrix-irc\"" = "ALL PRIVILEGES";
        };
      }
      {
        name = "meshcentral";
        ensurePermissions = { "DATABASE meshcentral" = "ALL PRIVILEGES"; };
      }
      {
        name = "wikijs";
        ensurePermissions = { "DATABASE wikijs" = "ALL PRIVILEGES"; };
      }
    ];
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE USER netdata;
      GRANT pg_monitor TO netdata;
    '';
    authentication = "host all all 172.16.0.0/12 md5";
    settings = { listen_addresses = lib.mkForce "localhost, 172.17.0.1"; };
  };
  # We need to wait for the 172.17.0.1 docker0 interface to be created.
  systemd.services.postgresql.after = [ "docker.service" ];

  # Regular backups for our database (every 6h)
  services.postgresqlBackup = {
    compression = "zstd";
    enable = true;
    location = "/var/garuda/backups/postgres";
  };

  # Meshcentral for easy remote access
  # manual installation as Nix version is outdated
  # Also adding in a Python module needed for monitoring our PostgreSQL database via Netdata
  environment.systemPackages = with pkgs; [ python310Packages.psycopg2 nodejs ];
  systemd.services.meshcentral = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    environment = { "NODE_ENV" = "production"; };
    path = [ pkgs.nodejs ];
    serviceConfig = {
      ExecStart =
        ''"${pkgs.nodejs}/bin/node" /opt/meshcentral/node_modules/meshcentral'';
      Group = "meshcentral";
      PrivateTmp = "true";
      Restart = "always";
      RestartSec = 10;
      User = "meshcentral";
      WorkingDirectory = "/opt/meshcentral";
    };
  };

  # Create Meshcentral user and group for the service to use
  users.groups.meshcentral = { };
  users.users.meshcentral = {
    home = "/opt/meshcentral";
    group = "meshcentral";
    isNormalUser = true;
  };

  # Our Mastodon
  services.mastodon = {
    configureNginx = true;
    enable = true;
    localDomain = "social.garudalinux.org";
    smtp = {
      authenticate = true;
      fromAddress = "mastodon.garudalinux.org";
      host = "mail.garudalinux.org";
      port = 587;
      user = "mastodon@garudalinux.org";
    };
    extraConfig = {
      "LOCAL_DOMAIN" = "garudalinux.org";
      "WEB_DOMAIN" = "social.garudalinux.org";
    };
    trustedProxy = "192.168.1.50";
  };
  services.nginx.virtualHosts."social.garudalinux.org".enableACME = lib.mkForce false;
  services.nginx.virtualHosts."social.garudalinux.org".useACMEHost = "garudalinux.org";

  # Open up ports for Meshcentral, Matrix & Wiki so ports can be forwarded and Nginx proxy
  # Yes, we are forwarding the database here (5432), there is no way around this. 
  # I have made sure the DB is only listening on internal ports however.
  networking.firewall.allowedTCPPorts =
    [ 3000 8008 8080 8081 22260 22261 5432 ];

  system.stateVersion = "22.05";
}
