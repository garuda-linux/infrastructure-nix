{ ... }: {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "web-dragon";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  boot.loader.initScript.enable = true;
  boot.isContainer = true;
  systemd.enableUnifiedCgroupHierarchy = false;

  # mailserver = {
  #   domains = "no-host.org";
  #   enable = true;
  #   loginAccounts.nico = {
  #     catchAll = "dr460nf1r3.org";
  #     hashedPassword =
  #       "$2y$10$kij/H2PcG7SI6rxRxJhhlO7WNmYqaTLu/US0PB4q7hEQ05tWkqoYS";
  #     name = "Nico Jensch";
  #   };
  #   extraVirtualAliases = {
  #     "postmaster@garudalinux.org" = "team@garudalinux.org";
  #     "admin@garudalinux.org" = "team@garudalinux.org";
  #     "root@garudalinux.org" = "team@garudalinux.org";
  #   };
  #   #forwards = {
  #   #};
  #   fqdn = "mail.garudalinux.org";
  #   indexDir = "/var/index";
  #   rebootAfterKernelUpgrade.enable = true;
  #   sendingFqdn = "dr460nf1r3.org";
  #   useFsLayout = true;
  #   certificateDomains = "no-host.org";
  #   dkimKeyBits = 3072;
  #   monitoring.alertAddress = "security@dr460nf1r3.org";
  #   monitoring.enable = true;
  #};

  system.stateVersion = "22.05";
}
