{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/29c0e263-3fac-4ad3-866b-29b88b7f8ef5";
    fsType = "ext4";
    options = [ "noatime" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CEE7-B438";
    fsType = "vfat";
  };
  fileSystems."/data_2" = {
    device = "/dev/disk/by-uuid/5ec5365b-0cf2-4ef0-9a07-00a5ef22f5d3";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
