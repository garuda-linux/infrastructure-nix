# Configure defaults applicable to all the Hetzner EX44 servers
{
  lib,
  pkgs,
  config,
  ...
}:
{
  # Increase /tmp & /run size to make better use of RAM
  boot = {
    # Latest seems to be buggy currently (2025-05-23)
    kernelPackages = pkgs.linuxPackages;
    loader.systemd-boot.enable = true;
    runSize = "50%";
    tmp = {
      tmpfsSize = "95%";
      useTmpfs = true;
    };
  };

  # Make use of all threads!
  security.allowSimultaneousMultithreading = true;

  # Raise limits to support many containers
  # (from LXC's recommendedSysctlSettings)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
    "fs.inotify.max_user_watches" = 1048576;
    "kernel.dmesg_restrict" = 1;
    "kernel.keys.maxkeys" = 2000;
    "kernel.pid_max" = 4194303;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv6.neigh.default.gc_thresh3" = 8192;
  };

  # Improve nspawn container performance since we grant all capabilities anyway
  # https://github.com/systemd/systemd/issues/18370#issuecomment-768645418
  environment.variables.SYSTEMD_SECCOMP = "0";

  nix.settings.max-jobs = 8;

  hardware.enableAllFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Better have an eye on the disks
  services = {
    smartd = {
      enable = true;
      extraOptions = [
        "-A /var/log/smartd/"
        "--interval=600"
      ];
    };
  };

  system.stateVersion = "25.05";
}
