{ sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  system.stateVersion = "23.05";
}

