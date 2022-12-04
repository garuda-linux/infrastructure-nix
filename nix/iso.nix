{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ./garuda/garuda.nix
    #<nixpkgs/nixos/modules/profiles/hardened.nix>
  ];

  networking.interfaces.ens18.ipv4.addresses = [{
    address = "78.129.140.86";
    prefixLength = 24;
  }];
  networking.hostName = "garuda-iso";
  networking.defaultGateway = "78.129.140.1";

  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [ docker-compose ];
  networking.firewall.allowedTCPPorts = [ 7777 ];

  system.stateVersion = "22.05";
}
