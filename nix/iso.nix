{ lib, 
sources, ... }: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  # Avoid running Netdata instances in containers
  services.garuda-monitoring.enable = lib.mkForce false;

  system.stateVersion = "23.05";
}

