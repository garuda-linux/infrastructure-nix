{ config
, lib
, pkgs
, sources
, ...
}:
let
  bridgeInterface = "br0";
  hostAddress = "10.0.5.1";
  mkContainer = name: extra:
    lib.mkMerge [{
      additionalCapabilities = lib.mkForce [ "all" ];
      allowedDevices = [
        { node = "/dev/fuse"; modifier = "rwm"; }
        { node = "/dev/mapper/control"; modifier = "rwm"; }
      ];
      autoStart = true;
      bindMounts = {
        "secrets" = lib.mkDefault {
          hostPath = "/var/garuda/secrets";
          isReadOnly = true;
          mountPoint = "/var/garuda/secrets";
        };
        "dev-fuse" = {
          hostPath = "/dev/fuse";
          mountPoint = "/dev/fuse";
        };
      };
      config = import ./${name}.nix;
      enableTun = true;
      ephemeral = false;
      extraFlags = [
        "--property=CPUQuota=80%"
        "--property=MemoryHigh=60G"
        "--property=MemoryMax=64G"
      ];
      hostAddress = hostAddress;
      hostBridge = bridgeInterface;
      privateNetwork = true;
      specialArgs = sources.specialArgs;
    }
      extra];
in
{
  imports = [
    ./hardware-configuration.nix
    ./garuda/garuda.nix
  ];

  # Boot stuff
  boot = {
    kernelPackages = pkgs.linuxPackages_xanmod_latest;
    loader.systemd-boot.enable = true;
    tmp.useTmpfs = true;
  };

  # Network configuration with a bridge interface
  networking = {
    bridges."${bridgeInterface}" = {
      interfaces = [ ];
    };
    defaultGateway = "116.202.208.65";
    hostName = "immortalis";
    interfaces = {
      "${bridgeInterface}".ipv4.addresses = [{
        address = hostAddress;
        prefixLength = 24;
      }];
      "eth0".ipv4.addresses = [{
        address = "116.202.208.112";
        prefixLength = 26;
      }];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "eth0";
      enableIPv6 = true;
    };
  };

  # Make use of all threads!
  security.allowSimultaneousMultithreading = true;

  # Raise limits to support many containers
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 524288;
    "fs.inotify.max_user_watches" = 524288;
    "kernel.pid_max" = 4194303;
  };

  # Improve nspawn container performance since we grant all capabilities anyway
  # https://github.com/systemd/systemd/issues/18370#issuecomment-768645418
  environment.variables.SYSTEMD_SECCOMP = "0";

  # Systemd-nspawn based NixOS containers
  containers = {
    "backup" = mkContainer "backup" {
      localAddress = "10.0.5.70/24";
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 226;
          protocol = "tcp";
        }
      ];
    };
    "chaotic-kde" = mkContainer "chaotic-kde" {
      bindMounts = {
        "repo" = {
          hostPath = "/data_2/containers/chaotic-kde/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data_2/containers/chaotic-kde/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
      extraFlags = lib.mkForce [
        "--property=CPUQuota=80%"
        "--property=MemoryHigh=60G"
        "--property=MemoryMax=64G"
      ];
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 225;
          protocol = "tcp";
        }
      ];
      localAddress = "10.0.5.120/24";
    };
    "docker" = mkContainer "docker" {
      bindMounts = {
        "compose" = {
          hostPath = "/data_1/containers/docker/";
          mountPoint = "/var/garuda/docker-compose-runner/all-in-one";
          isReadOnly = false;
        };
      };
      forwardPorts = [
        {
          containerPort = 27017;
          hostPort = 27017;
          protocol = "tcp";
        }
      ];
      localAddress = "10.0.5.20/24";
    };
    "forum" = mkContainer "forum" {
      bindMounts = {
        "forum" = {
          hostPath = "/data_1/containers/forum/";
          mountPoint = "/var/discourse";
          isReadOnly = false;
        };
      };
      localAddress = "10.0.5.60/24";
    };
    "mastodon" = mkContainer "mastodon" {
      bindMounts = {
        "mastodon" = {
          hostPath = "/data_1/containers/mastodon/mastodon";
          mountPoint = "/var/lib/mastodon";
          isReadOnly = false;
        };
      };
      bindMounts = {
        "redis" = {
          hostPath = "/data_1/containers/mastodon/redis/";
          mountPoint = "/var/lib/redis-mastodon";
          isReadOnly = false;
        };
      };
      localAddress = "10.0.5.90/24";
    };
    "meshcentral" = mkContainer "meshcentral" {
      bindMounts = {
        "meshcentral" = {
          hostPath = "/data_1/containers/meshcentral/";
          mountPoint = "/opt/meshcentral";
          isReadOnly = false;
        };
      };
      localAddress = "10.0.5.100/24";
    };
    "postgres" = mkContainer "postgres" {
      bindMounts = {
        "postgres" = {
          hostPath = "/data_1/containers/postgres/";
          mountPoint = "/var/garuda/backups/postgres";
          isReadOnly = false;
        };
      };
      localAddress = "10.0.5.110/24";
    };
    "repo" = mkContainer "repo" {
      bindMounts = {
        "repo" = {
          hostPath = "/data_2/containers/repo/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data_2/containers/repo/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
      extraFlags = lib.mkForce [
        "--property=CPUQuota=80%"
        "--property=MemoryHigh=60G"
        "--property=MemoryMax=64G"
      ];
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 224;
          protocol = "tcp";
        }
      ];
      localAddress = "10.0.5.30/24";
    };
    "runner" = mkContainer "runner" {
      extraFlags = lib.mkForce [
        "--property=CPUQuota=80%"
        "--property=MemoryHigh=60G"
        "--property=MemoryMax=64G"
      ];
      localAddress = "10.0.5.120/24";
    };
    "temeraire" = mkContainer "temeraire" {
      bindMounts = {
        "repo" = {
          hostPath = "/data_2/containers/temeraire/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data_2/containers/temeraire/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
      extraFlags = lib.mkForce [
        "--property=CPUQuota=80%"
        "--property=MemoryHigh=60G"
        "--property=MemoryMax=64G"
      ];
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 223;
          protocol = "tcp";
        }
        {
          containerPort = config.services.rsyncd.port;
          hostPort = config.services.rsyncd.port;
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
      localAddress = "10.0.5.80/24";
    };
    "web-front" = mkContainer "web-front" {
      bindMounts = {
        "nginx" = {
          hostPath = "/var/log/nginx";
          mountPoint = "/var/log/nginx";
          isReadOnly = false;
        };
      };
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 222;
          protocol = "tcp";
        }
        {
          containerPort = 80;
          hostPort = 80;
          protocol = "tcp";
        }
        {
          containerPort = 443;
          hostPort = 443;
          protocol = "tcp";
        }
        {
          containerPort = 443;
          hostPort = 443;
          protocol = "udp";
        }
      ];
      localAddress = "10.0.5.50/24";
    };
  };

  # Allow syscalls via an nspawn config file, because arguments with spaces work bad with containers.example.extraArgs
  environment.etc = {
    "systemd/nspawn/docker.nspawn".text = ''
      [Exec]
      SystemCallFilter=add_key keyctl bpf
    '';
    "systemd/nspawn/repo.nspawn".text = ''
      [Exec]
      SystemCallFilter=add_key keyctl bpf
    '';
    "systemd/nspawn/runner.nspawn".text = ''
      [Exec]
      SystemCallFilter=add_key keyctl bpf
    '';
  };

  systemd.services = {
    "container@docker".environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    "container@chaotic-kde" = {
      serviceConfig = {
        DevicePolicy = lib.mkForce "";
        DeviceAllow = lib.mkForce [ "" ];
        ExecStartPost = [
          (pkgs.writeShellScript "container-chaotic-kde-post" ''
            "${pkgs.coreutils}/bin/echo" "mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup" | "${pkgs.nixos-container}/bin/nixos-container" root-login repo
          '')
        ];
      };
      environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
      environment.SYSTEMD_NSPAWN_API_VFS_WRITABLE = "1";
    };
    "container@repo" = {
      serviceConfig = {
        DevicePolicy = lib.mkForce "";
        DeviceAllow = lib.mkForce [ "" ];
        ExecStartPost = [
          (pkgs.writeShellScript "container-repo-post" ''
            "${pkgs.coreutils}/bin/echo" "mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup" | "${pkgs.nixos-container}/bin/nixos-container" root-login repo
          '')
        ];
      };
      environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
      environment.SYSTEMD_NSPAWN_API_VFS_WRITABLE = "1";
    };
    "container@runner".environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
    "container@temeraire" = {
      serviceConfig = {
        DevicePolicy = lib.mkForce "";
        DeviceAllow = lib.mkForce [ "" ];
        ExecStartPost = [
          (pkgs.writeShellScript "container-temeraire-post" ''
            "${pkgs.coreutils}/bin/echo" "mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup" | "${pkgs.nixos-container}/bin/nixos-container" root-login repo
          '')
        ];
      };
      environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
      environment.SYSTEMD_NSPAWN_API_VFS_WRITABLE = "1";
    };
  };

  system.stateVersion = "23.05";
}

