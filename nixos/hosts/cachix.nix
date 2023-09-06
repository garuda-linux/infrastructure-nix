{ lib, pkgs, config, ... }: {
  imports = [
    ../garuda/garuda.nix
  ];

  options.cachix = lib.mkOption { type = lib.types.package; };

  config = {
    fileSystems."/" = { device = "nodev"; };
    boot.loader.grub.device = "nodev";
    cachix = pkgs.buildEnv {
      name = "cachix";
      paths = [ config.services.nginx.package config.services.cloudflared.package ];
    };
  };
}
