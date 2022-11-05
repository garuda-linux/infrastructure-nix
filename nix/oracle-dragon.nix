{ config, garuda-lib, lib, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  # Oracle provides DHCP
  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;
  networking.hostName = "oracle-dragon";

  system.stateVersion = "22.11";
}
