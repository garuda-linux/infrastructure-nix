{ inputs, ... }:
let
  system = "x86_64-linux";

  defaultModules = [
    "${inputs.nixpkgs}/nixos/modules/profiles/hardened.nix"
    inputs.home-manager.nixosModules.home-manager
    overlay-unstable
  ];

  inherit (inputs) nixpkgs;

  overlay-unstable = _: {
    nixpkgs.overlays = [
      (_final: prev: {
        unstable = inputs.nixpkgs.legacyPackages.${prev.system};
      })
    ];
  };

  specialArgs = {
    inherit inputs;
    sources = {
      buildiso = inputs.src-buildiso;
      chaotic-mirror = inputs.src-chaotic-mirror;
      chaotic-toolbox = inputs.src-chaotic-toolbox;
      chaotic-portable-builder = inputs.src-chaotic-portable-builder;
      cloudflare-ipv4 = inputs.src-cloudflare-ipv4;
      garuda-website = inputs.src-garuda-website;
      inherit defaultModules;
      inherit nixpkgs;
      inherit specialArgs;
      repoctl = inputs.src-repoctl;
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

  patchedNixosSystem = args:
    let
      inherit (args) system;
      unpatched = nixpkgs.legacyPackages."${system}";
      patches = builtins.filter (a: a != null) (nixpkgs.lib.mapAttrsToList (name: patch: if nixpkgs.lib.hasPrefix "nixos-patch-" name then patch else null) inputs);
      result =
        if builtins.length patches > 0 then
          import
            (unpatched.applyPatches
              {
                inherit patches;
                name = "nixpkgs-patched";
                src = nixpkgs;
              } + /nixos/lib/eval-config.nix)
            args
        else
          nixpkgs.lib.nixosSystem args;
    in
    result;

in
{
  flake = {
    nixosConfigurations = {
      "garuda-build" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [ ./hosts/garuda-build.nix ];
      };
      "garuda-mail" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [
          ./hosts/garuda-mail.nix
          inputs.nixos-mailserver.nixosModule
        ];
      };
      "immortalis" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [ ./hosts/immortalis.nix ];
      };
      "cachix" = patchedNixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [ ./hosts/cachix.nix ];
      };
    };
  };
}
