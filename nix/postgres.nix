{ pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

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
        ensurePermissions = { "DATABASE lemmy" = "ALL PRIVILEGES"; };
      }
      {
        name = "mastodon";
        ensurePermissions = { "DATABASE mastodon" = "ALL PRIVILEGES"; };
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
        name = "synapse";
        ensurePermissions = { "DATABASE synapse" = "ALL PRIVILEGES"; };
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

  # Open up ports for Postgres
  networking.firewall.allowedTCPPorts = [ 5432 ];

  system.stateVersion = "23.05";
}

