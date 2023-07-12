{ lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/containers.nix
  ];

  # Our Postgres database
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "meshcentral"
      "wikijs"
      "synapse"
      "matrix-telegram"
      "matrix-discord"
      "matrix-irc"
    ];
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

  # Open up ports for Postgres
  networking.firewall.allowedTCPPorts = [ 5432 ];

  system.stateVersion = "23.05";
}

