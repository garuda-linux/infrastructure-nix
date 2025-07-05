_: {
  # We want to have same UID's in all containers to allow sharing home directories
  garuda-lib.unifiedUID = true;

  fileSystems."/nix" = {
    device = "/data_1/nix";
    options = [ "bind" ];
    depends = [
      "/data_1"
    ];
  };

  services.openssh = {
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
