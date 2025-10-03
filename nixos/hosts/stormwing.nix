{
  config,
  lib,
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

  swapDevices = [
    {
      device = "/data_1/swapfile";
      size = 32 * 1024;
    }
  ];

  services.openssh.ports = [ 666 ];

  # Network configuration with a bridge interface
  networking = {
    defaultGateway = "157.180.57.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "stormwing";
    interfaces = {
      "eth0" = {
        ipv4.addresses = [
          {
            address = "157.180.57.51";
            prefixLength = 26;
          }
        ];
      };
    };
    # Specify these here to allow containers to access
    # our services from the internal network via NAT reflection
    nat.forwardPorts = [
      # Here because we need to take advantage of NAT reflection.
      # In general, SSH ports should not be here.
      {
        # chaotic-v4 (SSH)
        destination = "10.0.5.10:22";
        loopbackIPs = [ "157.180.57.51" ];
        proto = "tcp";
        sourcePort = 210;
      }
      {
        # iso-runner (SSH)
        destination = "10.0.5.20:22";
        loopbackIPs = [ "157.180.57.51" ];
        proto = "tcp";
        sourcePort = 220;
      }
      {
        # web-front (HTTP)
        destination = "10.0.5.40:80";
        loopbackIPs = [ "157.180.57.51" ];
        proto = "tcp";
        sourcePort = 80;
      }
      {
        # web-front (HTTPS)
        destination = "10.0.5.40:443";
        loopbackIPs = [ "157.180.57.51" ];
        proto = "tcp";
        sourcePort = 443;
      }
      {
        # web-front (HTTPS)
        destination = "10.0.5.40:443";
        loopbackIPs = [ "157.180.57.51" ];
        proto = "udp";
        sourcePort = 443;
      }
    ];
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
      chaotic-v4 = {
        config = import ./stormwing/chaotic-v4.nix;
        extraOptions = {
          bindMounts = {
            # Begin data_1
            "chaotic" = {
              hostPath = "/data_1/containers/chaotic-v4/chaotic";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/chaotic-v4";
            };
            "syncthing" = {
              hostPath = "/data_1/containers/chaotic-v4/syncthing";
              isReadOnly = false;
              mountPoint = "/var/lib/syncthing";
            };
            # End data_1
            # Begin data_2
            "chaotic-v4" = {
              hostPath = "/data_2/chaotic-v4/";
              isReadOnly = false;
              mountPoint = "/srv/http/repos";
            };
            "iso-builds" = {
              hostPath = "/data_2/iso/iso";
              isReadOnly = false;
              mountPoint = "/srv/http/iso";
            };
            # End data_2
          };
          forwardPorts = [
            {
              containerPort = 873;
              hostPort = 873;
              protocol = "tcp";
            }
            {
              containerPort = 21027;
              hostPort = 21027;
              protocol = "udp";
            }
            {
              containerPort = 22000;
              hostPort = 22000;
              protocol = "tcp";
            }
            {
              containerPort = 22000;
              hostPort = 22000;
              protocol = "udp";
            }
          ];
          enableTun = true;
        };
        ipAddress = "10.0.5.10";
        needsDocker = true;
        # Only entitled to 1/5 of the CPU resources in case of contention
        cpuWeight = 20;
        ioWeight = 20;
      };
      github-runner = {
        config = import ./stormwing/github-runner.nix;
        defaults = false;
        extraOptions = {
          bindMounts = {
            "token" = {
              hostPath = config.sops.secrets."compose/github-runner".path;
              isReadOnly = true;
              mountPoint = "/var/.github-runner.env";
            };
            "gitlab-config" = {
              hostPath = "/data_1/containers/github-runner/gitlab-runner";
              isReadOnly = false;
              mountPoint = "/etc/gitlab-runner";
            };
            "ssh-keys" = {
              hostPath = "/data_1/containers/github-runner/ssh";
              isReadOnly = false;
              mountPoint = "/etc/ssh";
            };
            "github-cache" = {
              hostPath = "/data_1/cache/github-runner";
              isReadOnly = false;
              mountPoint = "/var/cache/github-runner";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 230;
              protocol = "tcp";
            }
          ];
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.30";
        needsDocker = true;
        # Only entitled to 1/5 of the CPU resources in case of contention
        cpuWeight = 20;
        ioWeight = 20;
      };
      firedragon-runner = {
        config = import ./stormwing/firedragon-runner.nix;
        defaults = false;
        extraOptions = {
          bindMounts = {
            "firedragon-runner" = {
              hostPath = "/data_1/containers/firedragon-runner";
              isReadOnly = false;
              mountPoint = "/var/garuda/compose-runner/firedragon-runner";
            };
          };
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.50";
        needsDocker = true;
        # Only entitled to 10% of the CPU resources in case of contention
        cpuWeight = 10;
        ioWeight = 10;
      };
      iso-runner = {
        config = import ./stormwing/iso-runner.nix;
        extraOptions = {
          bindMounts = {
            "iso" = {
              hostPath = "/data_2/iso/";
              isReadOnly = false;
              mountPoint = "/var/garuda/buildiso";
            };
            "cache" = {
              hostPath = "/data_1/cache/iso-runner";
              isReadOnly = false;
              mountPoint = "/var/garuda/buildiso/cache";
            };
            "pacman_cache" = {
              hostPath = "/data_1/cache/pacman-cache";
              isReadOnly = false;
              mountPoint = "/var/cache/pacman/pkg";
            };
          };
        };
        ipAddress = "10.0.5.20";
        needsDocker = true;
      };
      web-front = {
        config = import ./stormwing/web-front.nix;
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
              hostPort = 240;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.40";
      };
    };
  };

  # Monitor a few services of the containers
  services = {
    netdata.configDir = {
      "go.d/web_log.conf" = pkgs.writeText "web_log.conf" ''
        jobs:
          - name: nginx
            path: /data_2/containers/web-front/nginx/access.log
      '';
    };
  };

  deployment = {
    targetHost = "157.180.57.51";
    targetPort = 666;
    targetUser = "ansible";
  };

  sops.secrets = {
    "compose/github-runner" = { };
  };
}
