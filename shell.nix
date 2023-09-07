# Shell for bootstrapping flake-enabled nix and other tooling
{ pkgs ? # If pkgs is not defined, instanciate nixpkgs from locked commit
  let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
  import nixpkgs { overlays = [ ]; }
, system ? builtins.currentSystem
, ...
}:
let
  devshell = import src { inherit system; };
  src = fetchTarball "https://github.com/numtide/devshell/archive/main.tar.gz";
in
devshell.mkShell {
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
      category = "deployment";
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
  packages = with pkgs; [
    ansible
    ansible-lint
    commitizen
    git
    nixFlakes
    manix
    nixos-generators
    rsync
    shfmt
    yamlfix
  ];
}
