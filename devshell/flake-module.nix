_:
{
  perSystem = { pkgs, ... }:
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
            category = "deployment";
            command = ''
              ansible-playbook playbooks/garuda.yml
            '';
          }
          {
            name = "apply";
            category = "deployment";
            command = ''
              ansible-playbook playbooks/apply.yml
            '';
          }
          {
            name = "clean";
            category = "tools";
            command = ''
              ansible-playbook playbooks/garbage_collect.yml
            '';
          }
          {
            name = "update";
            category = "deployment";
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
            category = "deployment";
          }
          {
            package = "yamlfix";
            category = "formatter";
          }
        ];
        motd = ''
          {202}🔨 Welcome to the Garuda infra-nix shell ❄️{reset}
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
