{ ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  # Base configuration
  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
  networking.hostName = "esxi-iso";
  networking.defaultGateway = "192.168.1.1";

  # This is on an ESXi, therefore we need the guest tools
  virtualisation.vmware.guest.headless = true;

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  system.stateVersion = "22.05";
}
