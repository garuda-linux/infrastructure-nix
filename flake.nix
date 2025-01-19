{
  description = "Garuda Linux infrastructure flake ❄️";

  nixConfig.extra-substituters = [ "https://garuda-linux.cachix.org" ];
  nixConfig.extra-trusted-public-keys = [ "garuda-linux.cachix.org-1:tWw7YBE6qZae0L6BbyNrHo8G8L4sHu5QoDp0OXv70bg=" ];

  inputs = {
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

    # The single source of truth
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05";

    # Our mailserver
    nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
    nixos-mailserver.inputs.flake-compat.follows = "flake-compat";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";
    nixos-mailserver.inputs.nixpkgs-24_11.follows = "nixpkgs";

    # Pre-commit hooks via nix-shell or nix develop
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.flake-compat.follows = "flake-compat";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

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
    src-chaotic-mirror.url = "github:chaotic-aur/docker-mirror";
    src-chaotic-mirror.flake = false;
    # TODO: https://github.com/NixOS/nix/pull/9163
    src-garuda-website = {
      type = "gitlab";
      owner = "garuda-linux";
      repo = "website%2Fgaruda";
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
  };

  outputs =
    { flake-parts
    , nixpkgs
    , pre-commit-hooks
    , self
    , ...
    } @ inputs:
    let
      perSystem =
        { pkgs
        , system
        , ...
        }: {
          apps.default = self.outputs.devShells.${system}.default.flakeApp;

          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              hooks = {
                actionlint.enable = true;
                ansible-lint.enable = true;
                check-json.enable = true;
                commitizen.enable = true;
                deadnix.enable = true;
                detect-private-keys.enable = true;
                flake-checker.enable = true;
                nil.enable = true;
                nixpkgs-fmt.enable = true;
                prettier.enable = true;
                statix.enable = true;
                yamllint.enable = true;
              };
              src = ./.;
            };
          };

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
              immortalis = "builds.garudalinux.org";
              ipv6-generator = builtins.readFile ./scripts/ipv6-generator.sh;
              makeDevshell = import "${inputs.devshell}/modules" pkgs;
              mkShell = config:
                (makeDevshell {
                  configuration = {
                    inherit config;
                    imports = [ ];
                  };
                }).shell;
            in
            rec {
              default = infra-nix-shell;
              infra-nix-shell = mkShell {
                devshell = {
                  name = "infra-nix";
                  startup = {
                    preCommitHooks.text = self.checks.${system}.pre-commit-check.shellHook;
                    dr460nixedEnv.text = ''
                      export LC_ALL="C.UTF-8"
                      export NIX_PATH=nixpkgs=${nixpkgs}
                    '';
                  };
                };
                commands = [
                  { package = "ansible"; }
                  { package = "rsync"; }
                  { package = "commitizen"; }
                  { package = "manix"; }
                  { package = "mdbook"; }
                  { package = "mdbook-admonish"; }
                  { package = "mdbook-emojicodes"; }
                  { package = "nodePackages.prettier"; }
                  { package = "nixos-install-tools"; }
                  { package = "pre-commit"; }
                  {
                    name = "apply";
                    help = "Applies the infra-nix configuration pushed to the servers";
                    command = ''
                      ansible-playbook playbooks/apply.yml
                    '';
                  }
                  {
                    name = "clean";
                    help = "Runs the garbage collection on the servers";
                    command = ''
                      ansible-playbook playbooks/garbage_collect.yml
                    '';
                  }
                  {
                    name = "deploy";
                    help = "Deploys the local NixOS configuration to the servers";
                    command = ''
                      ansible-playbook playbooks/garuda.yml
                    '';
                  }
                  {
                    name = "update";
                    help = "Performs a full system update on the servers bumping flake lock";
                    command = ''
                      ansible-playbook playbooks/system_update.yml
                    '';
                  }
                  {
                    name = "restart";
                    help = "Restarts all physical servers";
                    command = ''
                      ansible-playbook playbooks/reboot.yml
                    '';
                  }
                  {
                    name = "update-forum";
                    help = "Updates the Discourse container of our forum";
                    category = "infra-nix";
                    command = ''
                      # We are assuming the NixOS user is named the same as the one using it
                      ssh -p224 ${immortalis} "cd /var/discourse; sudo ./launcher rebuild app"
                    '';
                  }
                  {
                    name = "buildiso-remote";
                    help = "Spawns a buildiso shell on the iso-runner builder";
                    category = "infra-nix";
                    command = ''
                      # We are assuming the NixOS user is named the same as the one using it
                      ssh -p227 -t ${immortalis} "buildiso"
                    '';
                  }
                  {
                    name = "buildiso-local";
                    help = "Spawns a local buildiso shell to build to ./buildiso (needs Docker)";
                    category = "infra-nix";
                    command = buildiso;
                  }
                  {
                    name = "ipv6-generator";
                    help = "Generates random IPv6 addresses in our /64 subnet to help rorating them";
                    category = "infra-nix";
                    command = ipv6-generator;
                  }
                ];
                motd = ''
                  {202}🔨 Welcome to Garuda's infra-nix shell{reset} ❄️
                  $(type -p menu &>/dev/null && menu)
                '';
              };
            };

          formatter = pkgs.nixpkgs-fmt;

          packages = {
            docs =
              pkgs.runCommand "infra-docs"
                { nativeBuildInputs = with pkgs; [ bash mdbook ]; }
                ''
                  bash -c "errors=$(mdbook build -d $out ${./.}/docs |& grep ERROR)
                  if [ \"$errors\" ]; then
                    exit 1
                  fi"
                '';
          };
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./nixos/flake-module.nix
        inputs.devshell.flakeModule
        inputs.pre-commit-hooks.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-linux" ];
      inherit perSystem;
    };
}
