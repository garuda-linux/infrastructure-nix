{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../modules/garuda.nix
  ];

  # Lets build Garuda ISO here, serving is done via
  # Temeraire already 
  services = {
    garuda-iso.enable = true;
    nginx.enable = lib.mkForce false;
    rsyncd.enable = lib.mkForce false;
  };

  system.stateVersion = "23.05";
}
