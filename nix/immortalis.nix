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
      autoStart = true;
      hostAddress = hostAddress;
      hostBridge = bridgeInterface;
      config = import ./${name}.nix;
      specialArgs = sources.specialArgs;
      enableTun = true; # Tailscale
      ephemeral = false;
      privateNetwork = true;
      additionalCapabilities = lib.mkForce [ "all" ];
      bindMounts = {
        "secrets" = lib.mkDefault {
          hostPath = "/var/garuda/secrets";
          mountPoint = "/var/garuda/secrets";
          isReadOnly = true;
        };
        "dev-fuse" = { hostPath = "/dev/fuse"; mountPoint = "/dev/fuse"; };
      };
      allowedDevices = [
        { node = "/dev/fuse"; modifier = "rwm"; }
        { node = "/dev/mapper/control"; modifier = "rwm"; }
      ];
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
    # Fix "Failed to allocate directory watch: Too many open files"
    # or "Insufficent watch descriptors available."
    "fs.inotify.max_user_instances" = 524288; # max (uses up to 512 MB kernel memory)
    # Fix "Failed to add ... to directory watch: inotify watch limit reached"
    "fs.inotify.max_user_watches" = 524288; # max (uses up to 512 MB kernel memory)
    # Fix full PIDs, check with `lsof -n -l | wc -l` (default 32768)
    "kernel.pid_max" = 4194303; # 64-bit max
  };

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
          hostPath = "/data/containers/chaotic-kde/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data/containers/chaotic-kde/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
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
      localAddress = "10.0.5.60/24";
    };
    "mastodon" = mkContainer "mastodon" {
      localAddress = "10.0.5.90/24";
    };
    "meshcentral" = mkContainer "meshcentral" {
      localAddress = "10.0.5.100/24";
    };
    "monitor" = mkContainer "monitor" {
      localAddress = "10.0.5.40/24";
    };
    "postgres" = mkContainer "postgres" {
      localAddress = "10.0.5.110/24";
    };
    "repo" = mkContainer "repo" {
      bindMounts = {
        "repo" = {
          hostPath = "/data/containers/repo/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data/containers/repo/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
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
      localAddress = "10.0.5.120/24";
    };
    "temeraire" = mkContainer "temeraire" {
      bindMounts = {
        "repo" = {
          hostPath = "/data/containers/temeraire/repo";
          mountPoint = "/srv/http/repos";
          isReadOnly = false;
        };
        "cache" = {
          hostPath = "/data/containers/temeraire/cache";
          mountPoint = "/var/cache/chaotic";
          isReadOnly = false;
        };
      };
      forwardPorts = [
        {
          containerPort = 22;
          hostPort = 223;
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

  systemd.services."container@repo" = {
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
  };

  systemd.services."container@docker".environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";

  system.stateVersion = "23.05";
}

