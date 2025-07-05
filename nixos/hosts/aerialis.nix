{ ... }:
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
}
