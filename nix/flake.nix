{
  description = "Garuda Linux infrastructure NixOS config";

  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixos";
    };

    meshagent_x86_64 = {
      url = "https://mesh.garudalinux.org/meshagents?id=6";
      flake = false;
    };
    meshagent_aarch64 = {
      url = "https://mesh.garudalinux.org/meshagents?id=26";
      flake = false;
    };

    keys_nico = {
      url = "https://github.com/dr460nf1r3.keys";
      flake = false;
    };
    keys_tne = {
      url = "https://github.com/justtne.keys";
      flake = false;
    };
    keys_technetium1 = {
      url = "https://github.com/Technetium1.keys";
      flake = false;
    };
    keys_alexjp = {
      url = "https://github.com/alexjp.keys";
      flake = false;
    };


    src-chaotic-toolbox = {
      url = "github:chaotic-aur/toolbox";
      flake = false;
    };
    src-repoctl = {
      url = "github:cassava/repoctl";
      flake = false;
    };
    src-buildiso = {
      url = "git+https://gitlab.com/garuda-linux/tools/buildiso-docker";
      flake = false;
    };
    src-chaotic-mirror = {
      url = "github:chaotic-aur/docker-mirror";
      flake = false;
    };
  };

  outputs = { nixos, nixos-unstable, home-manager, ... }@attrs:
    let
      system = "x86_64-linux";
      specialArgs = {
        meshagent = {
          x86_64 = attrs.meshagent_x86_64;
          aarch64 = attrs.meshagent_aarch64;
        };
        sources = {
          buildiso = attrs.src-buildiso;
          chaotic-toolbox = attrs.src-chaotic-toolbox;
          repoctl = attrs.src-repoctl;
          chaotic-mirror = attrs.src-chaotic-mirror;
        };
        keys = {
          alexjp = attr.keys_alexjp; 
          nico = attrs.keys_nico;
          technetium1 = attrs.keys_technetium1;
          tne = attrs.keys_tne;
        };
      };
      overlay-unstable = ({ ... }: {
        nixpkgs.overlays = [
          (final: prev: {
            unstable = nixos-unstable.legacyPackages.${prev.system};
          })
        ];
      });
      defaultModules = [
        "${nixos}/nixos/modules/profiles/hardened.nix"
        home-manager.nixosModules.home-manager
        overlay-unstable
      ];
    in {
      nixosConfigurations."garuda-iso" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./iso.nix ];
      };
      nixosConfigurations."esxi-iso" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-iso.nix ];
      };
      nixosConfigurations."esxi-repo" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-repo.nix ];
      };
      nixosConfigurations."chaotic-dragon" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./chaotic-dragon.nix ];
      };
    };
}
