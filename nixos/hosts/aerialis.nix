{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../modules
    ./../modules/special/hetzner-ex44.nix
  ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [
      "defaults"
      "size=50%"
      "mode=755"
    ];
  };

  fileSystems."/data_1" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
    neededForBoot = true;
    options = [
      "defaults"
      "noatime"
      "nodiratime"
      "errors=remount-ro"
    ];
    depends = [
      "/"
    ];
  };

  fileSystems."/data_2" = {
    device = "/dev/disk/by-label/NIXDATA";
    fsType = "btrfs";
    options = [
      "defaults"
      "noatime"
      "nodiratime"
      "compress=zstd:1"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
  };

  services.openssh.ports = [ 666 ];

  # Network configuration with a bridge interface
  networking = {
    defaultGateway = "157.180.57.65";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "aerialis";
    interfaces = {
      "eth0" = {
        ipv4.addresses = [
          {
            address = "157.180.57.100";
            prefixLength = 26;
          }
        ];
      };
    };
    nat.forwardPorts = [
      {
        # web-front (HTTP)
        destination = "10.0.5.10:80";
        loopbackIPs = [ "157.180.57.100" ];
        proto = "tcp";
        sourcePort = 80;
      }
      {
        # web-front (HTTPS)
        destination = "10.0.5.10:443";
        loopbackIPs = [ "157.180.57.100" ];
        proto = "tcp";
        sourcePort = 443;
      }
      {
        # web-front (HTTPS)
        destination = "10.0.5.10:443";
        loopbackIPs = [ "157.180.57.100" ];
        proto = "udp";
        sourcePort = 443;
      }
      {
        # web-front (HTTPS)
        destination = "10.0.5.10:443";
        loopbackIPs = [ "157.180.57.100" ];
        proto = "udp";
        sourcePort = 443;
      }
    ];
    firewall.trustedInterfaces = [ "br0" ];
  };

  # Can't set this inside the containers
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  # Container config
  services.garuda-nspawn = {
    bridgeInterface = "br0";
    hostInterface = "eth0";
    hostIp = "10.0.5.1";
    dockerCache = "/data_1/dockercache/";

    defaults = {
      maxMemorySoft = 48318382080; # 45 GiB
      maxMemoryHard = 53687091200; # 50 GiB
      maxCpu = 18;
    };

    containers = {
      chaotic-backend = {
        config = import ./aerialis/chaotic-backend.nix;
        extraOptions = {
          bindMounts = {
            "chaotic" = {
              hostPath = "/data_2/containers/chaotic-backend/chaotic";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/chaotic-backend";
            };
          };
          enableTun = true;
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 270;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.70";
        needsDocker = true;
      };
      docker = {
        config = import ./aerialis/docker.nix;
        extraOptions = {
          bindMounts = {
            "compose" = {
              hostPath = "/data_1/containers/docker/";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/docker";
            };
            "nextcloud-local-backup" = {
              hostPath = "/data_2/backup/nextcloud-aio";
              isReadOnly = false;
              mountPoint = "/var/garuda/backups/nextcloud";
            };
          };
        };
        ipAddress = "10.0.5.60";
        needsDocker = true;
      };
      docker-proxied = {
        config = import ./aerialis/docker-proxied.nix;
        extraOptions = {
          bindMounts = {
            "compose" = {
              hostPath = "/data_1/containers/docker-proxied/";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/docker-proxied";
            };
          };
        };
        ipAddress = "10.0.5.50";
        needsDocker = true;
      };
      forum = {
        config = import ./aerialis/forum.nix;
        extraOptions = {
          bindMounts = {
            "forum" = {
              hostPath = "/data_1/containers/forum/";
              isReadOnly = false;
              mountPoint = "/var/discourse";
            };
          };
        };
        ipAddress = "10.0.5.40";
        needsDocker = true;
      };
      mastodon = {
        config = import ./aerialis/mastodon.nix;
        needsDocker = true;
        extraOptions = {
          bindMounts = {
            "mastodon" = {
              hostPath = "/data_2/containers/mastodon/mastodon";
              isReadOnly = false;
              mountPoint = "/var/lib/mastodon";
            };
            "compose" = {
              hostPath = "/data_1/containers/mastodon/compose";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/mastodon";
            };
          };
        };
        ipAddress = "10.0.5.30";
      };
      postgres = {
        config = import ./aerialis/postgres.nix;
        extraOptions = {
          bindMounts = {
            "data" = {
              hostPath = "/data_1/containers/postgres/data";
              isReadOnly = false;
              mountPoint = "/var/lib/postgresql";
            };
            "postgres_backup" = {
              hostPath = "/data_2/containers/postgres/backup";
              isReadOnly = false;
              mountPoint = "/var/garuda/backups/postgres";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 220;
              protocol = "tcp";
            }
            {
              containerPort = 5432;
              hostPort = 5432;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.20";
      };
      web-front = {
        config = import ./aerialis/web-front.nix;
        extraOptions = {
          bindMounts = {
            "acme" = {
              hostPath = "/data_2/containers/web-front/acme";
              isReadOnly = false;
              mountPoint = "/var/lib/acme";
            };
            "nginx" = {
              hostPath = "/data_2/containers/web-front/nginx";
              isReadOnly = false;
              mountPoint = "/var/log/nginx";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 210;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.10";
      };
    };
  };

  # Monitor a few services of the containers
  services = {
    netdata.configDir = {
      "go.d/postgres.conf" = pkgs.writeText "postgres.conf" ''
        jobs:
          - name: postgres
            dsn: 'postgres://netdata:netdata@10.0.5.20:5432/'
      '';
      "go.d/squidlog.conf" = pkgs.writeText "squidlog.conf" ''
        jobs:
          - name: squid
            path: /var/log/squid/access.log
            log_type: csv
            csv_config:
              format: '- resp_time client_address result_code resp_size req_method - - hierarchy mime_type'
      '';
      "go.d/web_log.conf" = pkgs.writeText "web_log.conf" ''
        jobs:
          - name: nginx
            path: /data_2/containers/web-front/nginx/access.log
      '';
    };
  };

  # Fix permissions of nginx log files to allow Netdata to read it (gets reset frequently)
  system.activationScripts.netdata = "chown 60:netdata -R /data_2/containers/web-front/nginx";

  # Backup configurations to Hetzner storage box
  programs.ssh.macs = [ "hmac-sha2-512" ];
  services.borgbackup.jobs = {
    backupToHetzner = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = ''
          cat "${config.sops.secrets."backup/repo_key".path}"
        '';
      };
      environment = {
        BORG_RSH = "ssh -i ${config.sops.secrets."backup/ssh_aerialis".path} -p 23";
      };
      exclude = [
        "/data_1/dockercache"
        "/data_1/dockerdata"
      ];
      paths = [
        "/data_1/containers"
        "/data_1/persistent/etc/ssh"
        "/data_2/backup/nextcloud-aio/"
        "/data_2/containers/chaotic-backend/chaotic/database"
        "/data_2/containers/mastodon"
        "/data_2/containers/postgres"
      ];
      prune.keep = {
        within = "1d";
        daily = 3;
        weekly = 1;
        monthly = 1;
      };
      repo = "u342919@u342919.your-storagebox.de:./aerialis";
      startAt = "daily";
    };
  };

  sops.secrets = {
    "backup/repo_key" = { };
    "backup/ssh_aerialis" = { };
  };

  deployment = {
    targetHost = "157.180.57.100";
    targetPort = 666;
    targetUser = "ansible";
  };
}
