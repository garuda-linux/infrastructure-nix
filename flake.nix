{
  description = "Garuda Linux infrastructure flake ❄️";

  inputs = {
    # Deployment tool
    colmena.url = "github:zhaofengli/colmena";

    # Devshell to set up a development environment
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    # Used by multiple flakes, have them use the same version
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    # Flake parts for easy flake management
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Home-manager for dotfile management
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Impermanence for keeping things clean
    impermanence.url = "github:nix-community/impermanence";

    # Lix-module, because it's awesome
    lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
    lix-module.inputs.nixpkgs.follows = "nixpkgs";

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    # Our mailserver
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    nixos-mailserver.inputs.flake-compat.follows = "flake-compat";
    nixos-mailserver.inputs.git-hooks.follows = "";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.inputs.nixpkgs-25_05.follows = "nixpkgs";

    # Pre-commit hooks via nix-shell or nix develop
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # Sops-nix for managing secrets
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    # Formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

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
    # TODO: https://github.com/NixOS/nix/pull/9163
    src-chaotic-portable-builder = {
      type = "gitlab";
      owner = "garuda-linux";
      repo = "tools%2Fchaotic-portable-builder";
      flake = false;
    };
    # TODO: https://github.com/NixOS/nix/pull/9163
    src-buildiso = {
      type = "gitlab";
      owner = "garuda-linux";
      repo = "tools%2Fbuildiso-docker";
      flake = false;
    };
    src-garuda-website = {
      type = "gitlab";
      owner = "garuda-linux";
      repo = "website%2Fwebsite-catppuccin";
      flake = false;
    };

    src-cloudflare-ipv4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
    src-cloudflare-authenticated_origin_pull_ca = {
      url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
      flake = false;
    };

    # Patches
    nixos-patch-netdata.url = "https://github.com/NixOS/nixpkgs/pull/410815.patch";
    nixos-patch-netdata.flake = false;
  };

  outputs =
    {
      colmena,
      flake-parts,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      perSystem =
        {
          pkgs,
          system,
          ...
        }:
        {
          apps.default = self.outputs.devShells.${system}.default.flakeApp;
          devShells =
            let
              buildiso = ''
                if ! command -v docker &>/dev/null; then
                  echo "This command requires docker to be installed. Please install Docker and try again."
                  exit 1
                fi
                if ! docker images | grep buildiso &>/dev/null; then
                  docker build ${inputs.src-buildiso} -t buildiso
                fi
                docker run --rm -it --privileged --name buildiso \
                       -v "./buildiso/buildiso:/var/cache/garuda-tools/garuda-chroots/buildiso" \
                       -v "./buildiso/cron:/var/spool/anacron" \
                       -v "./buildiso/pkg:/var/cache/pacman/pkg/" \
                       -v "./buildiso/iso:/var/cache/garuda-tools/garuda-builds/iso/" \
                       -v "./buildiso/logs:/var/cache/garuda-tools/garuda-logs/" \
                       buildiso /bin/bash
              '';
              stormwing = "builds.garudalinux.org";
              makeDevshell = import "${inputs.devshell}/modules" pkgs;
              mkShell =
                config:
                (makeDevshell {
                  configuration = {
                    inherit config;
                    imports = [ ];
                  };
                }).shell;
              shared_commands = [
                { package = "ansible"; }
                { package = "rsync"; }
                { package = "sops"; }
                {
                  name = "apply";
                  help = "Applies the infra-nix configuration pushed to the servers";
                  command = ''
                    pushd ansible &>/dev/null
                    ansible-playbook playbooks/apply.yml
                    popd &>/dev/null
                  '';
                }
                {
                  name = "clean";
                  help = "Runs the garbage collection on the servers";
                  command = ''
                    pushd ansible &>/dev/null
                    ansible-playbook playbooks/garbage_collect.yml
                    popd &>/dev/null
                  '';
                }
                {
                  name = "deploy";
                  help = "Deploys the local NixOS configuration to the servers";
                  command = ''
                    pushd ansible &>/dev/null
                    ansible-playbook playbooks/garuda.yml
                    popd &>/dev/null
                  '';
                }
                {
                  name = "update";
                  help = "Performs a full system update on the servers bumping flake lock";
                  command = ''
                    pushd ansible &>/dev/null
                    ansible-playbook playbooks/system_update.yml
                    popd &>/dev/null
                  '';
                }
                {
                  name = "restart";
                  help = "Restarts all physical servers";
                  command = ''
                    pushd ansible &>/dev/null
                    ansible-playbook playbooks/reboot.yml
                    popd &>/dev/null
                  '';
                }
                {
                  name = "buildiso-remote";
                  help = "Spawns a buildiso shell on the iso-runner builder";
                  category = "infra-nix";
                  command = ''
                    # We are assuming the NixOS user is named the same as the one using it
                    ssh -p220 -t ${stormwing} "buildiso"
                  '';
                }
                {
                  name = "buildiso-local";
                  help = "Spawns a local buildiso shell to build to ./buildiso (needs Docker)";
                  category = "infra-nix";
                  command = buildiso;
                }
              ];
            in
            rec {
              default = infra-nix-shell;
              infra-nix-shell = mkShell {
                devshell = {
                  name = "infra-nix";
                  startup = {
                    infra-nix-shell.text = ''
                      export LC_ALL="C.UTF-8"
                      export NIX_PATH=nixpkgs=${nixpkgs}
                    '';
                    pre-commit-hooks.text = self.checks.${system}.pre-commit-check.shellHook;
                  };
                };
                commands = [
                  { package = "commitizen"; }
                  { package = "manix"; }
                  { package = "mdbook"; }
                  { package = "mdbook-admonish"; }
                  { package = "mdbook-emojicodes"; }
                  { package = "pre-commit"; }
                  {
                    name = "colmena";
                    help = "Runs the Colmena deployment tool";
                    category = "infra-nix";
                    package = colmena.defaultPackage.${system};
                  }
                ] ++ shared_commands;
                motd = ''
                  {202}🔨 Welcome to Garuda's infra-nix shell{reset} ❄️
                  $(type -p menu &>/dev/null && menu)
                '';
              };
              minimal = mkShell {
                devshell = {
                  name = "minimal";
                  startup = {
                    infra-nix-shell.text = ''
                      export LC_ALL="C.UTF-8"
                      export NIX_PATH=nixpkgs=${nixpkgs}
                    '';
                  };
                };
                commands = shared_commands;
                motd = ''
                  {202}🔨 Welcome to Garuda's infra-nix minimal shell{reset} ❄️
                  $(type -p menu &>/dev/null && menu)
                '';
              };
            };

          checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
            hooks = {
              check-json.enable = true;
              commitizen.enable = true;
              detect-private-keys.enable = true;
              check-yaml.enable = true;
              ripsecrets.enable = true;
              treefmt = {
                enable = false;
                name = "treefmt";
                entry = "treefmt";
                types = [
                  "text"
                ];
                pass_filenames = false;
              };
            };
            src = ./.;
          };

          treefmt = {
            build.check = true;
            programs = {
              actionlint.enable = true;
              deadnix.enable = true;
              nixfmt.enable = true;
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
          };
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nixos/flake-module.nix
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      inherit perSystem;
    };
}
