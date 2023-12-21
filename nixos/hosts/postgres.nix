{ garuda-lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Our Postgres database
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "lemmy"
      "matrix-discord"
      "matrix-irc"
      "matrix-telegram"
      "meshcentral"
      "synapse"
      "wikijs"
    ];
    ensureUsers = [
      {
        name = "lemmy";
        ensureDBOwnership = true;
      }
      {
        name = "mastodon";
        ensureDBOwnership = true;
      }
      {
        name = "matrix-bridges";
      }
      {
        name = "meshcentral";
        ensureDBOwnership = true;
      }
      {
        name = "synapse";
        ensureDBOwnership = true;
      }
      {
        name = "wikijs";
        ensureDBOwnership = true;
      }
    ];
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE USER netdata;
      GRANT pg_monitor TO netdata;

      # After 23.11, ensurePermissions got deprecated
      GRANT ALL PRIVILEGES ON DATABASE matrix-bridges TO matrix-discord;
      GRANT ALL PRIVILEGES ON DATABASE matrix-bridges TO matrix-irc;
      GRANT ALL PRIVILEGES ON DATABASE matrix-bridges TO matrix-telegram;
    '';
    authentication = "host all all 10.0.5.0/24 md5";
    # We don't need to worry about different interfaces, because the only interface 
    # available is eth0, which is fully isolated
    enableTCPIP = true;
  };

  # Regular backups for our database (every 6h)
  services.postgresqlBackup = {
    compression = "zstd";
    enable = true;
    location = "/var/garuda/backups/postgres";
  };

  # Run daily synapse state compressor on Matrix database
  systemd.services.synapse_auto_compressor = {
    description = "Run synapse state compressor on Matrix db";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        set -e
        ${pkgs.matrix-synapse-tools.rust-synapse-compress-state}/bin/synapse_auto_compressor \
          -p postgresql://${garuda-lib.secrets.matrix.db_string}@10.0.5.50/synapse -c 500 -n 100
      '';
      Restart = "on-failure";
      RestartSec = "30";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.synapse_auto_compressor = {
    description = "Run synapse state compressor on Matrix db";
    timerConfig.OnCalendar = [ "daily" ];
    wantedBy = [ "timers.target" ];
  };

  # Open up ports for Postgres
  networking.firewall.allowedTCPPorts = [ 5432 ];

  system.stateVersion = "23.05";
}

