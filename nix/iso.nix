{ sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # This is a container, run less services
  garuda-lib.isContainer = true;

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  system.stateVersion = "23.05";
}

