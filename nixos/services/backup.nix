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
      default = 4;
    };

    keepWeekly = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    keepMonthly = lib.mkOption {
      type = lib.types.int;
      default = 1;
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

    services.borgmatic = {
      enable = true;
      settings = {
        source_directories = cfg.sourceDirectories;
        exclude_patterns = cfg.excludePatterns;
        repositories = [
          {
            path = "ssh://${cfg.user}@${cfg.host}/./${cfg.name}";
            inherit (cfg) label;
          }
        ];
        encryption_passphrase = "{credential systemd borgmatic.pw}";
        ssh_command = "ssh -i ${config.sops.secrets.${cfg.sshKeySecret}.path} -p ${toString cfg.port}";
        compression = "auto,zstd";
        archive_name_format = "${cfg.name}-{now:%Y-%m-%dT%H:%M:%S}";
        keep_within = cfg.keepWithin;
        keep_daily = cfg.keepDaily;
        keep_weekly = cfg.keepWeekly;
        keep_monthly = cfg.keepMonthly;
      };
    };

    systemd.services."borgmatic".serviceConfig.LoadCredential = "borgmatic.pw:${repositoryKey}";

    systemd.services.borgmatic-init = {
      description = "Initialize borgmatic backup repository";
      serviceConfig = {
        Type = "oneshot";
        LoadCredential = "borgmatic.pw:${repositoryKey}";
        ExecStart = "${pkgs.borgmatic}/bin/borgmatic init --encryption repokey-blake2";
        PrivateTmp = true;
      };
    };

    systemd.services.prometheus-borgmatic-exporter.serviceConfig = {
      After = [ "borgmatic.service" ];
      Requires = [ "borgmatic.service" ];
      LoadCredential = "borgmatic.pw:${repositoryKey}";
    };

    services.prometheus.exporters.borgmatic.user = "root";
    services.prometheus.exporters.borgmatic.group = "root";

    sops.secrets = garuda-lib.mkSecrets [
      cfg.repositoryKeySecret
      cfg.sshKeySecret
    ];
  };
}
