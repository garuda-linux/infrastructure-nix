{
  description = "Garuda Linux infrastructure flake ❄️";

  inputs = {
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
    impermanence.inputs.home-manager.follows = "home-manager";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Infrastructure diagrams
    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.flake-parts.follows = "flake-parts";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";

    # Our mailserver
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/main";
    nixos-mailserver.inputs.flake-compat.follows = "flake-compat";
    nixos-mailserver.inputs.git-hooks.follows = "";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

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
    keys_stefan.url = "https://github.com/stefanwimmer128.keys";
    keys_stefan.flake = false;

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
    src-cloudflare-ipv4 = {
      url = "https://www.cloudflare.com/ips-v4";
      flake = false;
    };
    src-cloudflare-authenticated_origin_pull_ca = {
      url = "https://developers.cloudflare.com/ssl/static/authenticated_origin_pull_ca.pem";
      flake = false;
    };

    # Patches
    nixos-patch-nixos-container.url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/499574.patch";
    nixos-patch-nixos-container.flake = false;
    # CVE-2026-109618, CVE-2026-109619
    nixos-patch-php.url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/576853.patch";
    nixos-patch-php.flake = false;
  };

  outputs =
    {
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
          packages =
            let
              pkgs' = pkgs.extend (import ./pkgs/overlay.nix);
            in
            {
              inherit (pkgs') garuda-startpage garuda-website;
            };

          devShells =
            let
              inherit (pkgs) lib;

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

              commands = [
                {
                  name = "deploy";
                  help = "Builds and switches the servers to the local configuration (args go to colmena apply, e.g. --on aerialis)";
                  text = ''
                    colmena apply "$@"
                  '';
                }
                {
                  name = "clean";
                  help = "Runs the garbage collection on the servers";
                  text = ''
                    colmena exec "$@" -- sudo nh clean all
                  '';
                }
                {
                  name = "update";
                  help = "Bumps flake.lock and deploys it to the servers for the next boot";
                  text = ''
                    nix flake update
                    colmena apply boot "$@"
                  '';
                }
                {
                  name = "restart";
                  help = "Restarts all physical servers";
                  text = ''
                    colmena exec "$@" -- sudo systemctl reboot
                  '';
                }
                {
                  name = "topology";
                  help = "Renders the infrastructure diagrams (nix-topology) to docs/src/topology";
                  text = ''
                    cd "$(git rev-parse --show-toplevel)"
                    out="$(nix build --no-link --print-out-paths .#topology.x86_64-linux.config.output "$@")"
                    mkdir -p docs/src/topology
                    install -m 644 "$out"/*.svg docs/src/topology/
                    echo "Updated $(ls docs/src/topology/*.svg | wc -l) diagrams in docs/src/topology"
                  '';
                }
                {
                  name = "buildiso-remote";
                  help = "Spawns a buildiso shell on the iso-runner builder";
                  text = ''
                    # We are assuming the NixOS user is named the same as the one using it
                    ssh -p220 -t ${stormwing} "buildiso"
                  '';
                }
                {
                  name = "buildiso-local";
                  help = "Spawns a local buildiso shell to build to ./buildiso (needs Docker)";
                  text = buildiso;
                }
              ];

              commandPackages = map (command: pkgs.writeShellScriptBin command.name command.text) commands;

              commandList = lib.concatMapStrings (command: ''
                printf '  %-15s %s\n' ${lib.escapeShellArg command.name} ${lib.escapeShellArg command.help}
              '') commands;

              sharedPackages = [
                pkgs.colmena
                pkgs.dnscontrol
                pkgs.git
                pkgs.sops
              ]
              ++ commandPackages;

              env = ''
                export LC_ALL="C.UTF-8"
                export NIX_PATH=nixpkgs=${nixpkgs}
              '';
            in
            {
              default = pkgs.mkShell {
                name = "infra-nix";
                packages = [ pkgs.prek ] ++ sharedPackages;
                shellHook = ''
                  ${env}
                  (cd dns && dnscontrol write-types &>/dev/null)
                  ${self.checks.${system}.pre-commit-check.shellHook}
                  printf "\033[1;35mWelcome to Garuda's infra-nix shell\033[0m ❄️\n"
                  ${commandList}
                '';
              };
              minimal = pkgs.mkShell {
                name = "minimal";
                packages = sharedPackages;
                shellHook = ''
                  ${env}
                  printf "\033[1;35mWelcome to Garuda's infra-nix minimal shell\033[0m ❄️\n"
                  ${commandList}
                '';
              };
            };

          checks = {
            dnscontrol = pkgs.runCommand "dnscontrol" { } ''
              cd ${./dns}
              ${pkgs.dnscontrol}/bin/dnscontrol check
              touch $out
            '';

            pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
              package = pkgs.prek;
              excludes = [ "\\.svg$" ];
              hooks = {
                check-json.enable = true;
                check-yaml.enable = true;
                commitizen.enable = true;
                detect-private-keys.enable = true;
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
          };

          topology.modules = [ ./nixos/topology.nix ];

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
        inputs.nix-topology.flakeModule
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
