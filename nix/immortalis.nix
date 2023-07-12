{ config, pkgs, lib, sources, ... }:
let
  hostAddress = "10.0.5.1";
  bridgeInterface = "br0";
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

  # Bootloader
  boot.loader.systemd-boot.enable = true;

  # Base network configuration
  networking.interfaces."eth0".ipv4.addresses = [{
    address = "116.202.208.112";
    prefixLength = 26;
  }];

  networking.hostName = "immortalis";
  networking.defaultGateway = "116.202.208.65";

  # Provide internet access to containers
  networking.nat = {
    enable = true;
    internalInterfaces = [ "br0" ];
    externalInterface = "eth0";
    enableIPv6 = true;
  };
  networking.bridges."${bridgeInterface}" = {
    interfaces = [ ];
  };
  networking.interfaces."${bridgeInterface}".ipv4.addresses = [{
    address = hostAddress;
    prefixLength = 24;
  }];

  # Allow more unprivileged containers
  boot.kernel.sysctl = {
    "kernel.keys.maxkeys" = 10000;
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

  # allow syscalls via an nspawn config file, because arguments with spaces work bad with containers.example.extraArgs
  environment.etc."systemd/nspawn/repo.nspawn".text = ''
    [Exec]
    SystemCallFilter=add_key keyctl bpf
  '';

  systemd.services."container@docker".environment.SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";
  # allow syscalls via an nspawn config file, because arguments with spaces work bad with containers.example.extraArgs
  environment.etc."systemd/nspawn/docker.nspawn".text = ''
    [Exec]
    SystemCallFilter=add_key keyctl bpf
  '';

  containers = {
    "backup" = mkContainer "backup" {
      localAddress = "10.0.5.70/24";
    };
    "chaotic-kde" = mkContainer "chaotic-kde" {
      localAddress = "10.0.5.120/24";
    };
    "docker" = mkContainer "docker" {
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
      localAddress = "10.0.5.30/24";
    };
    "temeraire" = mkContainer "temeraire" {
      localAddress = "10.0.5.80/24";
    };
    "web-front" = mkContainer "web-front" {
      localAddress = "10.0.5.50/24";
    };
  };

  system.stateVersion = "23.05";
}

