{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.backup.borgmatic;

  repositoryKey = config.sops.secrets.${cfg.repositoryKeySecret}.path;

  # Runs a PostgreSQL client tool inside the nixos-container that hosts the database,
  # as the postgres user, so peer auth applies and client and server versions match
  inContainer =
    tool:
    pkgs.writeShellScript "borgmatic-${tool}" ''
      exec ${pkgs.nixos-container}/bin/nixos-container run ${cfg.postgresqlContainer} -- \
        /run/current-system/sw/bin/runuser -u postgres -- /run/current-system/sw/bin/${tool} "$@"
    '';

  settings =
    pingUrl:
    {
      source_directories = cfg.sourceDirectories;
      exclude_patterns = cfg.excludePatterns;
      repositories = [
        {
          path = "ssh://${cfg.user}@${cfg.host}/./${cfg.name}";
          inherit (cfg) label;
        }
      ];
      encryption_passphrase = "{credential file ${repositoryKey}}";
      ssh_command = "ssh -i ${config.sops.secrets.${cfg.sshKeySecret}.path} -p ${toString cfg.port}";
      compression = "auto,zstd";
      archive_name_format = "${cfg.name}-{now:%Y-%m-%dT%H:%M:%S}";
      keep_within = cfg.keepWithin;
      keep_daily = cfg.keepDaily;
      keep_weekly = cfg.keepWeekly;
      keep_monthly = cfg.keepMonthly;
      checks = [
        {
          name = "repository";
          frequency = "1 week";
        }
        {
          name = "archives";
          frequency = "1 week";
        }
        {
          name = "data";
          frequency = "1 month";
        }
      ];
      healthchecks.ping_url = pingUrl;
    }
    // lib.optionalAttrs (cfg.postgresqlContainer != null) {
      # pg_dumpall streams one plain SQL dump into the archive
      postgresql_databases = [
        {
          name = "all";
          pg_dump_command = toString (inContainer "pg_dumpall");
          pg_restore_command = toString (inContainer "pg_restore");
          psql_command = toString (inContainer "psql");
        }
      ];
    };

  # JSON is valid YAML. The rendered file only exists at runtime, as it carries the ping URL.
  configTemplate = builtins.toJSON (settings config.sops.placeholder.${cfg.healthchecksSecret});
  configForCheck = pkgs.writeText "borgmatic-config-check.yaml" (
    builtins.toJSON (settings "https://hc-ping.com/00000000-0000-0000-0000-000000000000")
  );
in
{
  options.garuda.backup.borgmatic = {
    enable = lib.mkEnableOption "borgmatic backups to a remote repository";

    name = lib.mkOption {
      type = lib.types.str;
      description = "Repository subdirectory and archive name prefix.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      description = "User to log in to the backup host as.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      description = "Backup host to connect to.";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 22;
      description = "SSH port of the backup host.";
    };

    label = lib.mkOption {
      type = lib.types.str;
      default = "remote";
      description = "Label of the repository in borgmatic's settings.";
    };

    repositoryKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "backup/repo_key";
      description = "sops secret holding the repository encryption passphrase.";
    };

    sshKeySecret = lib.mkOption {
      type = lib.types.str;
      default = "backup/ssh_key";
      description = "sops secret holding the SSH key used to reach the backup host.";
    };

    knownHosts = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption { type = lib.types.str; };
            publicKey = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = [ ];
      description = "Host keys of the backup host to pin.";
    };

    sourceDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Directories to back up.";
    };

    excludePatterns = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Patterns to exclude from the backup.";
    };

    keepWithin = lib.mkOption {
      type = lib.types.str;
      default = "1d";
    };

    keepDaily = lib.mkOption {
      type = lib.types.int;
      default = 2;
    };

    keepWeekly = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    keepMonthly = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    healthchecksSecret = lib.mkOption {
      type = lib.types.str;
      default = "backup/healthchecks_ping_url";
      description = "sops secret holding the healthchecks.io ping URL. healthchecks.io mails on failed and on missed runs.";
    };

    postgresqlContainer = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "nixos-container running PostgreSQL. borgmatic dumps all of its databases with pg_dumpall.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      macs = [ "hmac-sha2-512" ];
      knownHosts = lib.listToAttrs (
        map (
          entry:
          lib.nameValuePair entry.name {
            hostNames = [ cfg.host ];
            inherit (entry) publicKey;
          }
        ) cfg.knownHosts
      );
    };

    # No services.borgmatic.settings: the config is a sops template (root only), so the
    # ping URL stays out of the store. The template is validated at build time instead.
    services.borgmatic.enable = true;

    sops.templates."borgmatic-config" = {
      content = configTemplate;
      path = "/etc/borgmatic/config.yaml";
    };

    system.checks = [
      (pkgs.runCommand "borgmatic-config-validation" { } ''
        ${pkgs.borgmatic}/bin/borgmatic -c ${configForCheck} config validate
        touch $out
      '')
    ];

    systemd.services."borgmatic".serviceConfig = {
      LoadCredential = "borgmatic.pw:${repositoryKey}";
    }
    // lib.optionalAttrs (cfg.postgresqlContainer != null) {
      # nixos-container run enters the container with nsenter, which the packaged unit's sandbox blocks
      RestrictNamespaces = false;
      CapabilityBoundingSet = [
        "CAP_SETGID"
        "CAP_SETUID"
        "CAP_SYS_ADMIN"
        "CAP_SYS_CHROOT"
        "CAP_SYS_PTRACE"
      ];
      SystemCallFilter = [ "setns" ];
    };

    systemd.services.borgmatic-init = {
      description = "Initialize borgmatic backup repository";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.borgmatic}/bin/borgmatic init --encryption repokey-blake2";
        PrivateTmp = true;
      };
    };

    systemd.services.borgmatic-prune = {
      description = "Prune borgmatic backup repository (retention from config)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.borgmatic}/bin/borgmatic prune";
        PrivateTmp = true;
      };
    };

    systemd.services.prometheus-borgmatic-exporter.serviceConfig = {
      After = [ "borgmatic.service" ];
      Requires = [ "borgmatic.service" ];
    };

    services.prometheus.exporters.borgmatic.user = "root";
    services.prometheus.exporters.borgmatic.group = "root";

    sops.secrets = garuda-lib.mkSecrets [
      cfg.healthchecksSecret
      cfg.repositoryKeySecret
      cfg.sshKeySecret
    ];
  };
}
