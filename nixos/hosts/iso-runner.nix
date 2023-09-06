{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../garuda/garuda.nix
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
