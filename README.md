# Garuda Linux server configurations

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org) [![run nix flake check](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/flake_check.yml/badge.svg?branch=main)](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/flake_check.yml)

## General information

- Our current infrastructure is hosted in one of [these](https://www.hetzner.com/dedicated-rootserver/ax102).
- The only other server not being contained in this dedicated server is our mail server.
- Both servers are being backed up to Hetzner storage boxes via [Borg](https://www.borgbackup.org/).
- After multiple different setups, we settled on [NixOS](https://nixos.org/) as our main OS as it provides reproducible and atomically updated system states
- Most (sub)domains are protected by Cloudflare while also making use of its caching feature. Exemptions are services such as our mail server and parts violating Cloudflares rules such as proxying Piped content.

## Quick links

- [Common maintenance tasks](./hosts/common.md)
- [Host: garuda-mail](./hosts/garuda-mail.md)
- [Host: immortalis](./hosts/immortalis.md)

## Devshell and tooling

This NixOS flake provides a [devshell](https://github.com/numtide/devshell) which contains all deployment tools as well as handy aliases for common tasks.
The only requirement for using it is having the Nix package manager available. It can be installed on various distributions via the package manager or the following script:

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
```

After that, the shell can be invoked as follows:

```sh
nix-shell # Legacy, non-flakes way
nix develop # The intended way to use the devshell
```

To enable flakes and the direct usage of `nix develop` follow this [wiki article](https://nixos.wiki/wiki/Flakes#Other_Distros:_Without_Home-Manager). After running either command, new commands are available to perform the following actions:

```sh
[infra-nix]

ansible-core    - Radically simple IT automation
apply           - Applies the infra-nix configuration pushed to the servers
buildiso-local  - Spawns a local buildiso shell to build to ./buildiso (needs Docker)
buildiso-remote - Spawn a buildiso shell on the iso-runner builder
clean           - Runs the garbage collection on the servers
deploy          - Deploys the local NixOS configuration to the servers
update          - Performs a full system update on the servers by bumping flake lock
update-forum    - Updates the Discourse container of our forum
update-toolbox  - Updates the locked Chaotic toolbox commit and deploys the changes
update-website  - Updates the locked website commit and deploys the changes
```
