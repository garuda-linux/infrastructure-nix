{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../modules
  ];

  # Base configuration
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/f52d63bd-a9e6-48a2-a25f-1772b988c424";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 6 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  networking.interfaces.ens3.ipv4.addresses = [
    {
      address = "94.16.112.218";
      prefixLength = 22;
    }
  ];
  networking.hostName = "garuda-mail";
  networking.defaultGateway = "94.16.112.3";

  # GRUB
  boot.loader.grub.devices = [ "/dev/vda" ];

  # At least try to prevent the insane spam of login attempts
  services.openssh.ports = [ 1022 ];

  services.garuda-monitoring.enable = lib.mkForce false;

  system.stateVersion = "22.05";
}
