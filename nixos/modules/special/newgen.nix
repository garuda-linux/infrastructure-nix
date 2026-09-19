_: {
  # We want to have same UID's in all containers to allow sharing home directories
  garuda-lib.unifiedUID = true;

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
    depends = [ "/" ];
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

  fileSystems."/nix" = {
    device = "/data_1/nix";
    fsType = "none";
    options = [ "bind" ];
    depends = [
      "/data_1"
    ];
  };

  services.openssh = {
    ports = [ 666 ];
    hostKeys = [
      {
        type = "ed25519";
        path = "/data_1/persistent/etc/ssh/ssh_host_ed25519_key";
      }
      {
        type = "rsa";
        bits = 4096;
        path = "/data_1/persistent/etc/ssh/ssh_host_rsa_key";
      }
    ];
  };

  services.garuda-nspawn = {
    bridgeInterface = "br0";
    hostInterface = "eth0";
    hostIp = "10.0.5.1";
    defaults = {
      maxMemorySoft = 48318382080; # 45 GiB
      maxMemoryHard = 53687091200; # 50 GiB
      maxCpu = 18;
    };
  };

  networking.firewall.trustedInterfaces = [ "br0" ];

  garuda-lib.sshkeys = {
    ed25519 = "/data_1/persistent/etc/ssh/ssh_host_ed25519_key";
    rsa = "/data_1/persistent/etc/ssh/ssh_host_rsa_key";
  };

  environment.persistence."/data_1/persistent" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/home"
      "/var/cache/netdata"
      "/var/cache/tailscale"
      "/var/lib/netdata"
      "/var/lib/nixos"
      "/var/lib/tailscale"
      "/var/lib/vnstat"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
