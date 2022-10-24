{ ... }: {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-iso";
  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  system.stateVersion = "22.05";
}
