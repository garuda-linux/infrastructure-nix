{ inputs, self, ... }:
let

  system = "x86_64-linux";

  defaultModules = [
    "${inputs.nixpkgs}/nixos/modules/profiles/hardened.nix"
    inputs.home-manager.nixosModules.home-manager
    inputs.nixos-mailserver.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../pkgs
  ];

  newGenModules = [
    inputs.impermanence.nixosModules.impermanence
    ./modules/special/newgen.nix
  ];

  inherit (inputs) nixpkgs;

  specialArgs = {
    inherit inputs self;
    sources = {
      chaotic-portable-builder = inputs.src-chaotic-portable-builder;
      cloudflare-ipv4 = inputs.src-cloudflare-ipv4;
      cloudflare-authenticated_origin_pull_ca = inputs.src-cloudflare-authenticated_origin_pull_ca;
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
      stefan = inputs.keys_stefan;
      technetium1 = inputs.keys_technetium1;
      tne = inputs.keys_tne;
      xiota = inputs.keys_xiota;
    };
  };

  patches = builtins.filter (a: a != null) (
    nixpkgs.lib.mapAttrsToList (
      name: patch: if nixpkgs.lib.hasPrefix "nixos-patch-" name then patch else null
    ) inputs
  );

  patchedNixpkgs =
    if builtins.length patches > 0 then
      nixpkgs.legacyPackages.${system}.applyPatches {
        inherit patches;
        name = "nixpkgs-patched";
        src = nixpkgs;
      }
    else
      nixpkgs;

  hosts = {
    stormwing = defaultModules ++ newGenModules ++ [ ./hosts/stormwing.nix ];
    aerialis = defaultModules ++ newGenModules ++ [ ./hosts/aerialis.nix ];
  };

  pkgs = nixpkgs.legacyPackages.${system};
  makeHive =
    rawHive:
    import "${pkgs.colmena.src}/src/nix/hive/eval.nix" {
      inherit rawHive;
      colmenaOptions = import "${pkgs.colmena.src}/src/nix/hive/options.nix";
      colmenaModules = import "${pkgs.colmena.src}/src/nix/hive/modules.nix";
      hermetic = true;
    };

  colmenaHive = {
    meta = {
      nixpkgs = pkgs;
      nodeNixpkgs = builtins.mapAttrs (_: value: value.pkgs) self.nixosConfigurations;
      nodeSpecialArgs = builtins.mapAttrs (_: value: value._module.specialArgs) self.nixosConfigurations;
    };
    defaults.deployment.targetUser = "deploy";
  }
  // builtins.mapAttrs (name: value: {
    imports = value._module.args.modules;
    deployment = {
      targetHost = "${name}.garudalinux.org";
      targetPort = builtins.head value.config.services.openssh.ports;
    };
  }) self.nixosConfigurations;

in
{
  flake = {
    nixosConfigurations = builtins.mapAttrs (
      _: modules:
      (
        if builtins.length patches > 0 then
          import "${patchedNixpkgs}/nixos/lib/eval-config.nix"
        else
          nixpkgs.lib.nixosSystem
      )
        {
          inherit modules specialArgs system;
        }
    ) hosts;

    colmenaHive = makeHive colmenaHive;
  };
}
