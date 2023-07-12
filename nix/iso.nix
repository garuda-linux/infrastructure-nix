{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/containers.nix
  ];

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;

  system.stateVersion = "23.05";
}

