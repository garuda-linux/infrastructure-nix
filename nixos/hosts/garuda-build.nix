{ ... }: {
  imports = [
    ../modules
    ./garuda-build/hardware-configuration.nix
  ];

  # Base configuration
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "216.158.66.108";
    prefixLength = 24;
  }];
  networking.hostName = "garuda-build";
  networking.defaultGateway = "216.158.66.97";

  system.stateVersion = "22.05";
}
