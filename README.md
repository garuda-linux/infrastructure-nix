# Garuda Linux server configurations

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org) [![deploy docs](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/pages.yml/badge.svg)](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/pages.yml)

## General information

- Our current infrastructure is hosted in one of [these](https://www.hetzner.com/dedicated-rootserver/ax102).
- The only other server not being contained in this dedicated server is our mail server, as well as a legacy build server.
- The first two mentioned servers are being backed up to Hetzner storage boxes via [Borg](https://www.borgbackup.org/).
- After multiple different setups, we settled on [NixOS](https://nixos.org/) as our main OS as it provides reproducible
  and atomically updated system states
- Cloudflare protects Most (sub)domains while also making use of its caching feature.
  Exemptions are services such as our mail server and parts violating Cloudflares rules such as proxying Piped content.
- Cloudflare Access in combination with Cloudflared is used to secure access to high-risk services such as admin panels.

## Quick links

- [Common maintenance tasks](https://docs.garudalinux.net/common)
- [Host: garuda-mail](https://docs.garudalinux.net/hosts/garuda-mail)
- [Host: immortalis](https://docs.garudalinux.net/hosts/immortalis)

## Devshell and how to enter it

This NixOS flake provides a [devshell](https://github.com/numtide/devshell)
which contains all deployment tools as well as handy aliases for common tasks.
The only requirement for using it is having the Nix package manager available.
It can be installed on various distributions via the package manager or the following
script ([click me for more information](https://zero-to-nix.com/start/install)):

```shell
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix -o nix-install.sh # Check its content afterwards
sh ./nix-install.sh install --diagnostic-endpoint=""
```

This installs the Nix packages with flakes already pre-enabled. After that, the shell can be invoked as follows:

```shell
nix develop # The intended way to use the devshell
nix-shell # Legacy, non-flakes way if flakes are not available for some reason
```

This also sets up pre-commit-hooks and shows the currently implemented tasks, which can be executed by running the
command.

```shell
🔨 Welcome to Garuda's infra-nix shell ❄️

[[general commands]]

  ansible-core        - Radically simple IT automation
  apply               - Applies the infra-nix configuration pushed to the servers
  clean               - Runs the garbage collection on the servers
  commitizen          - Tool to create committing rules for projects, auto bump versions, and generate changelogs
  deploy              - Deploys the local NixOS configuration to the servers
  manix               - Fast CLI documentation searcher for Nix
  mdbook              - Create books from MarkDown
  mdbook-admonish     - Preprocessor for mdbook to add Material Design admonishments
  mdbook-emojicodes   - MDBook preprocessor for converting emojicodes (e.g. `: cat :`) into emojis 🐱
  menu                - prints this menu
  nixos-install-tools - The essential commands from the NixOS installer as a package
  pre-commit          - Framework for managing and maintaining multi-language pre-commit hooks
  prettier            - Prettier is an opinionated code formatter
  rsync               - Fast incremental file transfer utility
  update              - Performs a full system update on the servers bumping flake lock

[infra-nix]

  buildiso-local      - Spawns a local buildiso shell to build to ./buildiso (needs Docker)
  buildiso-remote     - Spawns a buildiso shell on the iso-runner builder
  ipv6-generator      - Generates random IPv6 addresses in our /64 subnet to help rorating them
  update-forum        - Updates the Discourse container of our forum
  update-toolbox      - Updates the locked Chaotic toolbox commit and deploys the changes

```
