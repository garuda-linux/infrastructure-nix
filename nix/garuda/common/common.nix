{ pkgs, lib, garuda-lib, config, ... }: {
  imports = [
    ./users.nix
    ./acme.nix
  ];
  networking.nameservers = [ "1.1.1.1" ];

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  programs.mosh.enable = true;
  environment.variables = { MOSH_SERVER_NETWORK_TMOUT="604800"; };

  services.garuda-meshagent.enable = lib.mkDefault true;
  services.garuda-meshagent.mshFile = garuda-lib.meshagent_msh;
  services.garuda-meshagent.agentBinary = builtins.fetchurl "https://mesh.garudalinux.org/meshagents?id=${if builtins.currentSystem == "aarch64-linux" then "26" else "6"}";

  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.autoPrune.flags = [ "-a" ];

  environment.systemPackages = [ pkgs.python3 pkgs.micro pkgs.htop pkgs.git ];

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ garuda-lib.zerotier_network ];

  services.garuda-monitoring.enable = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nixpkgs.config.allowUnfree = true;
}
