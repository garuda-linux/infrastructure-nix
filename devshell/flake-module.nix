_:
{
  perSystem = { pkgs, ... }:
    let
      immortalis = "116.202.208.112";
    in
    {
      # The default development shell spawned by "nix develop"
      devshells.default = {
        commands = [
          {
            package = "pre-commit";
            category = "formatter";
          }
          {
            package = "manix";
            category = "handbook";
          }
          {
            name = "deploy";
            help = "Deploy the local NixOS configuration to the servers";
            category = "infra-nix";
            command = ''
              ansible-playbook playbooks/garuda.yml
            '';
          }
          {
            name = "apply";
            help = "Apply the infra-nix configuration pushed to the servers";
            category = "infra-nix";
            command = ''
              ansible-playbook playbooks/apply.yml
            '';
          }
          {
            name = "clean";
            help = "Runs the garbage collection on the servers";
            category = "infra-nix";
            command = ''
              ansible-playbook playbooks/garbage_collect.yml
            '';
          }
          {
            name = "update";
            help = "Performs a full system update on the servers bumping flake lock";
            category = "infra-nix";
            command = ''
              ansible-playbook playbooks/system_update.yml
            '';
          }
          {
            package = "nixpkgs-fmt";
            category = "formatter";
          }
          {
            package = "ansible";
            category = "infra-nix";
          }
          {
            name = "update-forum";
            help = "Updates the Discourse container of our forum";
            category = "infra-nix";
            command = ''
              # We are assuming the MixOS user is named the same as the one using it
              ssh -p224 ${immortalis} "cd /var/disourse; sudo ./launcher rebuild app"
            '';
          }
          {
            name = "buildiso";
            help = "Spawn a buildiso shell on the builder";
            category = "infra-nix";
            command = ''
              # We are assuming the NixOS user is named the same as the one using it
              ssh -p227 -t ${immortalis} "buildiso"
            '';
          }
          {
            name = "update-website";
            help = "Updates the locked website commit and deploys the changes";
            category = "infra-nix";
            command = ''
              nix flake lock --update-input src-garuda-website
              ansible-playbook playbooks/garuda.yml -l immortalis
              ansible-playbook playbooks/apply.yml -l immortalis
            '';
          }
          {
            name = "update-toolbox";
            help = "Updates the locked Chaotic toolbox commit and deploys the changes";
            category = "infra-nix";
            command = ''
              nix flake lock --update-input src-chaotic-toolbox
              ansible-playbook playbooks/garuda.yml -l immortalis
              ansible-playbook playbooks/apply.yml -l immortalis
            '';
          }
          {
            package = "yamlfix";
            category = "formatter";
          }
        ];
        motd = ''
          {202}🔨 Welcome to Garuda's infra-nix shell{reset} ❄️
          $(type -p menu &>/dev/null && menu)
        '';
        name = "infra-nix";
      };

      # Pre-commit linters & formatters
      pre-commit = {
        check.enable = true;
        inherit pkgs;
        settings = {
          hooks = {
            actionlint.enable = true;
            ansible-lint.enable = true;
            commitizen.enable = true;
            deadnix.enable = true;
            nil.enable = true;
            nixpkgs-fmt.enable = true;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
            statix.enable = true;
            yamllint.enable = true;
          };
          settings.deadnix = {
            edit = true;
            hidden = true;
            noLambdaArg = true;
          };
          src = ../.;
        };
      };
    };
}
