{ pkgs, ... }: {
  imports = [
    ./users.nix
    ./acme/acme.nix
  ];
  networking.nameservers = [ "1.1.1.1" ];

  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;

  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.autoPrune.flags = [ "-a" ];

  environment.systemPackages = [ pkgs.python3 pkgs.micro pkgs.htop pkgs.git ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
