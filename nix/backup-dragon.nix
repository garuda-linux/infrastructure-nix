{ ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.30";
    prefixLength = 24;
  }];
  networking.hostName = "backup-dragon";
  networking.defaultGateway = "192.168.1.1";

  services.borgbackup.repos = { authorizedKeys = [ "keys.borg" ]; };

  system.stateVersion = "22.05";
}
