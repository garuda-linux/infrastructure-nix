{ pkgs, lib, garuda-lib, config, ... }: {
  imports = [
    ./users.nix
    ./acme.nix
    ./nginx.nix
  ];
  networking.nameservers = [ "1.1.1.1" ];

  zramSwap.enable = true;

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  programs.mosh.enable = true;
  environment.variables = { MOSH_SERVER_NETWORK_TMOUT="604800"; };

  services.garuda-meshagent.enable = lib.mkDefault true;
  services.garuda-meshagent.mshFile = garuda-lib.secrets.meshagent_msh;
  services.garuda-meshagent.agentBinary = builtins.fetchurl "https://mesh.garudalinux.org/meshagents?id=${if builtins.currentSystem == "aarch64-linux" then "26" else "6"}";

  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.autoPrune.flags = [ "-a" ];

  environment.systemPackages = [ pkgs.python3 pkgs.micro pkgs.htop pkgs.git ];

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ garuda-lib.secrets.zerotier_network ];

  services.garuda-monitoring.enable = true;
  services.garuda-monitoring.parent = "10.241.0.10";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nixpkgs.config.allowUnfree = true;
}
