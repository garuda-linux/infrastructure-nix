{
  inputs = {
    nixos.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    meshagent_x86_64 = { url = "https://mesh.garudalinux.org/meshagents?id=6"; flake = false; };
    meshagent_aarch64 = { url = "https://mesh.garudalinux.org/meshagents?id=26"; flake = false; };

    keys_nico = { url = "https://github.com/dr460nf1r3.keys"; flake = false; };
    keys_tne = { url = "https://github.com/justtne.keys"; flake = false; };

    src-chaotic-toolbox = { url = "github:chaotic-aur/toolbox"; flake = false; };
    src-repoctl = { url = "github:cassava/repoctl"; flake = false; };
    src-buildiso = { url = "https://gitlab.com/garuda-linux/tools/buildiso-docker/-/archive/master/buildiso-docker-master.tar.gz"; flake = false; };
  };

  outputs = { self, nixos, nixos-unstable, ... }@attrs:
  let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = nixos-unstable.legacyPackages.${prev.system};
      };
  in {
    nixosConfigurations."garuda-iso" = nixos.lib.nixosSystem {
      inherit system;
      specialArgs = attrs;
      modules = [
        # Overlays-module makes "pkgs.unstable" available in configuration.nix
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
        ./iso.nix
      ];
    };
    nixosConfigurations."esxi-iso" = nixos.lib.nixosSystem {
      inherit system;
      specialArgs = attrs;
      modules = [
        # Overlays-module makes "pkgs.unstable" available in configuration.nix
        ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
        ./esxi-iso.nix
      ];
    };
  };
}