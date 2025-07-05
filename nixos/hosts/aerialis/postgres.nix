{
  inputs,
  pkgs,
  sources,
  config,
  lib,
  ...
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
  imports = sources.defaultModules ++ [ ../../modules ];

  # Our Postgres database
  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "chaotic-aur"
      "mastodon"
      "wikijs"
    ];
    ensureUsers = [
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
      {
        name = "chaotic-router";
      }
    ];
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE USER netdata;
      GRANT pg_monitor TO netdata;
    '';
    authentication = lib.mkForce ''
      local all all peer
      host chaotic-aur chaotic-router 0.0.0.0/0 scram-sha-256
      # Reject anything else coming from the outside world somehow someway
      host all all 10.0.5.1/32 reject
      # Allow connections from the internal network
      host all all 10.0.5.0/24 md5
      # Block the rest of the internet
      host all all 0.0.0.0/0 reject
    '';
    # This is publically accesible now through port 5432, however only the chaotic-router user can access the database through the internet
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
    initialPasswordFile = config.sops.secrets."postgres/pg_admin".path;
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

  sops.secrets."postgres/pg_admin" = { };

  system.stateVersion = "25.05";
}
