{ ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
  networking.hostName = "esxi-iso";
  networking.defaultGateway = "192.168.1.1";

  services.garuda-iso.enable = true;
  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  system.stateVersion = "22.05";
}
