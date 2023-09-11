{
  description = "Garuda Linux infrastructure flake ❄️";

  nixConfig.extra-substituters = [ "https://garuda-linux.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "garuda-linux.cachix.org-1:tWw7YBE6qZae0L6BbyNrHo8G8L4sHu5QoDp0OXv70bg=" ];

  inputs = {
    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    devshell.inputs.systems.follows = "systems";

    # Used by multiple flakes, have them use the same version
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # Flake parts for easy flake management
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Required by pre-commit-hooks
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    # Gitignore common input
    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";

    # Home-manager for dotfile management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.05";

    # Our mailserver
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    nixos-mailserver.inputs.flake-compat.follows = "flake-compat";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    # Meshagent agents for remote management
    meshagent_x86_64.url = "https://mesh.garudalinux.org/meshagents?id=6";
    meshagent_x86_64.flake = false;
    meshagent_aarch64.url = "https://mesh.garudalinux.org/meshagents?id=26";
    meshagent_aarch64.flake = false;

    # Pre-commit hooks via nix-shell or nix develop
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks.inputs.flake-utils.follows = "flake-utils";
    pre-commit-hooks.inputs.gitignore.follows = "gitignore";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.inputs.nixpkgs-stable.follows = "nixpkgs-stable";

    # SSH keys of maintainers
    keys_nico.url = "https://github.com/dr460nf1r3.keys";
    keys_nico.flake = false;
    keys_tne.url = "https://github.com/justtne.keys";
    keys_tne.flake = false;
    keys_frank.url = "https://github.com/fgd-garuda.keys";
    keys_frank.flake = false;
    keys_technetium1.url = "https://github.com/technetium1.keys";
    keys_technetium1.flake = false;
    keys_alexjp.url = "https://github.com/alexjp.keys";
    keys_alexjp.flake = false;
    keys_xiota.url = "https://github.com/xiota.keys";
    keys_xiota.flake = false;
    keys_pedrohlc.url = "https://github.com/pedrohlc.keys";
    keys_pedrohlc.flake = false;

    # Sources for custom applications and files
    src-chaotic-toolbox.url = "github:chaotic-aur/toolbox";
    src-chaotic-toolbox.flake = false;
    src-repoctl.url = "github:cassava/repoctl";
    src-repoctl.flake = false;
    src-buildiso.url = "gitlab:garuda-linux%2Ftools/buildiso-docker";
    src-buildiso.flake = false;
    src-chaotic-mirror.url = "github:chaotic-aur/docker-mirror";
    src-chaotic-mirror.flake = false;
    src-garuda-website.url = "gitlab:garuda-linux%2Fwebsite/garuda";
    src-garuda-website.flake = false;
    src-cloudflare-ipv4.url = "https://www.cloudflare.com/ips-v4";
    src-cloudflare-ipv4.flake = false;

    # Common input
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { flake-parts
    , pre-commit-hooks
    , self
    , ...
    } @ inputs:
    flake-parts.lib.mkFlake { inherit inputs; }
      {
        imports = [
          ./devshell/flake-module.nix
          ./nixos/flake-module.nix
          inputs.devshell.flakeModule
          inputs.pre-commit-hooks.flakeModule
        ];

        systems = [ "x86_64-linux" "aarch64-linux" ];

        perSystem = { pkgs, system, ... }: {
          # Enter devshell via "nix run .#apps.x86_64-linux.devshell"
          apps.devshell = self.outputs.devShells.${system}.default.flakeApp;

          # Run nixpkgs-fmt via "nix fmt"
          formatter = pkgs.nixpkgs-fmt;
        };
      };
}
