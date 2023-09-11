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
    meshagent = {
      aarch64 = inputs.meshagent_aarch64;
      x86_64 = inputs.meshagent_x86_64;
    };
    sources = {
      buildiso = inputs.src-buildiso;
      chaotic-mirror = inputs.src-chaotic-mirror;
      chaotic-toolbox = inputs.src-chaotic-toolbox;
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
in
{
  flake = {
    nixosConfigurations = {
      "garuda-build" = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [ ./hosts/garuda-build.nix ];
      };
      "garuda-mail" = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [
          ./hosts/garuda-mail.nix
          inputs.nixos-mailserver.nixosModule
        ];
      };
      "immortalis" = nixpkgs.lib.nixosSystem {
        inherit system;
        inherit specialArgs;
        modules = defaultModules ++ [ ./hosts/immortalis.nix ];
      };
    };
  };
}
