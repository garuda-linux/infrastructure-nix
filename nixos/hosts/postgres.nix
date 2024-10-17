{ garuda-lib
, inputs
, pkgs
, sources
, config
, lib
, ...
}:
let
  server_config = pkgs.writeText "server-config" ''
    {
      "Servers": {
        "1": {
          "Name": "Main",
          "Group": "Garuda",
          "Username": "pgadmin",
          "Host": "/var/run/postgresql",
          "Port": 5432,
          "SSLMode": "prefer",
          "MaintenanceDB": "postgres",
          "PassFile": "/dev/null",
          "Shared": true,
          "SharedUsername": "pgadmin"
        }
      }
    }
  '';
in
{
  imports = sources.defaultModules ++ [ ../modules ];

  # Our Postgres database
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "lemmy"
      "mastodon"
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
        name = "wikijs";
        ensureDBOwnership = true;
      }
      {
        name = "pgadmin";
        ensureClauses.superuser = true;
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

  services.pgadmin = {
    enable = true;
    initialEmail = "team@garudalinux.org";
    initialPasswordFile = garuda-lib.secrets.pgadmin_password;
    openFirewall = true;
    settings = {
      FIXED_BINARY_PATHS = {
        "pg" = "${config.services.postgresql.package}/bin";
      };
      SUPPORT_SSH_TUNNEL = false;
      AUTHENTICATION_SOURCES = [ "webserver" ];
      WEBSERVER_REMOTE_USER = "X-Forwarded-User";
      MASTER_PASSWORD_REQUIRED = false;
    };
    package = inputs.nixpkgs-stable.legacyPackages."${pkgs.system}".pgadmin4;
  };

  systemd.services.pgadmin = {
    preStart = lib.mkAfter ''
      EMAIL=${lib.escapeShellArg config.services.pgadmin.initialEmail}
      FILE=${lib.escapeShellArg server_config}
      ${config.services.pgadmin.package}/bin/pgadmin4-cli load-servers "$FILE" --user "$EMAIL"
    '';
  };

  # Open up ports for Postgres
  networking.firewall.allowedTCPPorts = [ 5432 ];

  system.stateVersion = "23.05";
}

