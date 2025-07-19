{ inputs, self, ... }:
let
  conf = self.nixosConfigurations;

  system = "x86_64-linux";

  defaultModules = [
    "${inputs.nixpkgs}/nixos/modules/profiles/hardened.nix"
    inputs.home-manager.nixosModules.home-manager
    inputs.lix-module.nixosModules.lixFromNixpkgs
    inputs.nixos-mailserver.nixosModule
    inputs.sops-nix.nixosModules.sops
  ];

  newGenModules = [
    inputs.impermanence.nixosModules.impermanence
    ./modules/special/newgen.nix
  ];

  inherit (inputs) nixpkgs;

  specialArgs = {
    inherit inputs;
    sources = {
      chaotic-portable-builder = inputs.src-chaotic-portable-builder;
      cloudflare-ipv4 = inputs.src-cloudflare-ipv4;
      cloudflare-authenticated_origin_pull_ca = inputs.src-cloudflare-authenticated_origin_pull_ca;
      garuda-website = inputs.src-garuda-website;
      buildiso = inputs.src-buildiso;
      inherit defaultModules;
      inherit nixpkgs;
      inherit specialArgs;
    };
    keys = {
      alexjp = inputs.keys_alexjp;
      frank = inputs.keys_frank;
      nico = inputs.keys_nico;
      pedrohlc = inputs.keys_pedrohlc;
      technetium1 = inputs.keys_technetium1;
      tne = inputs.keys_tne;
      xiota = inputs.keys_xiota;
    };
  };

  patchedNixosSystem =
    args:
    let
      inherit (args) system;
      unpatched = nixpkgs.legacyPackages."${system}";
      patches = builtins.filter (a: a != null) (
        nixpkgs.lib.mapAttrsToList (
          name: patch: if nixpkgs.lib.hasPrefix "nixos-patch-" name then patch else null
        ) inputs
      );
      result =
        if builtins.length patches > 0 then
          import (
            unpatched.applyPatches {
              inherit patches;
              name = "nixpkgs-patched";
              src = nixpkgs;
            }
            + /nixos/lib/eval-config.nix
          ) args
        else
          nixpkgs.lib.nixosSystem args;
    in
    result;

in
{
  flake = {
    nixosConfigurations = {
      "stormwing" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ newGenModules ++ [ ./hosts/stormwing.nix ];
        extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];
      };
      "aerialis" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ newGenModules ++ [ ./hosts/aerialis.nix ];
        extraModules = [ inputs.colmena.nixosModules.deploymentOptions ];
      };
      "garuda-mail" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [
          ./hosts/garuda-mail.nix
          inputs.nixos-mailserver.nixosModule
        ];
      };
    };

    colmena = {
      defaults.deployment = {
        allowLocalDeployment = true;
        buildOnTarget = true;
      };
      meta = {
        description = "Garuda Linux infrastructure";
        nixpkgs = import inputs.nixpkgs { inherit system; };
        nodeNixpkgs = builtins.mapAttrs (_name: value: value.pkgs) conf;
        nodeSpecialArgs = builtins.mapAttrs (_name: value: value._module.specialArgs) conf;
      };
    } // builtins.mapAttrs (_name: value: { imports = value._module.args.modules; }) conf;
    colmenaHive = inputs.colmena.lib.makeHive self.outputs.colmena;
  };
}
