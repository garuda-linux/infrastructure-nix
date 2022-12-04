{
  description = "Garuda Linux infrastructure NixOS config";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixos-unstable";
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
      url = "gitlab:garuda-linux%2Ftools/buildiso-docker";
      flake = false;
    };
    src-chaotic-mirror = {
      url = "github:chaotic-aur/docker-mirror";
      flake = false;
    };
    src-garuda-website = {
      url = "gitlab:garuda-linux%2Fwebsite/garuda";
      flake = false;
    };
    src-cloudflare-ipv4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
  };

  outputs = { nixos-unstable, home-manager, ... }@attrs:
    let
      nixos = nixos-unstable;
      system = "x86_64-linux";
      specialArgs = {
        meshagent = {
          x86_64 = attrs.meshagent_x86_64;
          aarch64 = attrs.meshagent_aarch64;
        };
        sources = {
          buildiso = attrs.src-buildiso;
          chaotic-mirror = attrs.src-chaotic-mirror;
          chaotic-toolbox = attrs.src-chaotic-toolbox;
          cloudflare-ipv4 = attrs.src-cloudflare-ipv4;
          garuda-website = attrs.src-garuda-website;
          repoctl = attrs.src-repoctl;
        };
        keys = {
          alexjp = attrs.keys_alexjp;
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
      nixosConfigurations."garuda-build" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./garuda-build.nix ];
      };
      nixosConfigurations."esxi-build" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-build.nix ];
      };
      nixosConfigurations."esxi-repo" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-repo.nix ];
      };
      nixosConfigurations."backup-dragon" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./backup-dragon.nix ];
      };
      nixosConfigurations."chaotic-dragon" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./chaotic-dragon.nix ];
      };
      nixosConfigurations."web-dragon" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./web-dragon.nix ];
      };
      nixosConfigurations."monitor-dragon" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./monitor-dragon.nix ];
      };
      nixosConfigurations."esxi-web" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-web.nix ];
      };
      nixosConfigurations."esxi-web-two" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-web-two.nix ];
      };
      nixosConfigurations."esxi-cloud" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-cloud.nix ];
      };
      nixosConfigurations."esxi-forum" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./esxi-forum.nix ];
      };
      nixosConfigurations."oracle-dragon" = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./oracle-dragon.nix ];
      };
      nixosConfigurations."cachix" = nixos.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgs;
        modules = defaultModules ++ [ ./cachix.nix ];
      };
    };
}
