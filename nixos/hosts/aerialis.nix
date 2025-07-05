{ lib, ... }:
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
    firewall.trustedInterfaces = [ "br0" ];
  };

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
          ephemeral = lib.mkForce true;
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
              mountPoint = "/var/garuda/compose-runner/all-in-one";
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
              mountPoint = "/var/garuda/compose-runner/proxied";
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
        extraOptions = {
          bindMounts = {
            "mastodon" = {
              hostPath = "/data_2/containers/mastodon/mastodon";
              isReadOnly = false;
              mountPoint = "/var/lib/mastodon";
            };
          };
          bindMounts = {
            "redis" = {
              hostPath = "/data_1/containers/mastodon/redis/";
              isReadOnly = false;
              mountPoint = "/var/lib/redis-mastodon";
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
              hostPort = 229;
              protocol = "tcp";
            }
            {
              containerPort = 5432;
              hostPort = 5432;
              protocol = "tcp";
            }
          ];
          ephemeral = lib.mkForce true;
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
              hostPort = 222;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.10";
      };
    };
  };
}
