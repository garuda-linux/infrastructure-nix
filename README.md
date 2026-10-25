# Garuda Linux server configurations

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org) [![deploy docs](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/pages.yml/badge.svg)](https://github.com/garuda-linux/infrastructure-nix/actions/workflows/pages.yml)

## General information

- Our current infrastructure is hosted in two of [these](https://www.hetzner.com/dedicated-rootserver/ex44).
- The servers are being backed up to Hetzner storage boxes via [Borg](https://www.borgbackup.org/), driven by
  [borgmatic](https://torsion.org/borgmatic/).
- After multiple different setups, we settled on [NixOS](https://nixos.org/) as our main OS as it provides reproducible
  and atomically updated system states
- Cloudflare protects most (sub)domains while also making use of its caching feature.
  Exemptions are services such as our mail server and parts violating Cloudflares rules such as proxying Mastodon video content.
- Cloudflare Access in combination with Cloudflared is used to secure access to high-risk services such as admin panels.
- Monitoring and alerting are self-hosted, based on Prometheus, Grafana, Loki and Alertmanager (see
  [Monitoring](./services/monitoring.md)).

## Quick links

- [Common maintenance tasks](https://docs.garudalinux.net/common)
- [Host: aerialis](https://docs.garudalinux.net/hosts/aerialis)
- [Host: stormwing](https://docs.garudalinux.net/hosts/stormwing)

## Dev shell and how to enter it

This NixOS flake provides a plain `pkgs.mkShell` dev shell
which contains all deployment tools as well as handy commands for common tasks.
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

This also sets up pre-commit-hooks and lists the available commands, which can be executed by running them.
The tools `colmena`, `dnscontrol`, `git`, `prek` and `sops` are on the PATH as well.

```shell
Welcome to Garuda's infra-nix shell ❄️
  deploy          Builds and switches the servers to the local configuration (args go to colmena apply, e.g. --on aerialis)
  clean           Runs the garbage collection on the servers
  update          Bumps flake.lock and deploys it to the servers for the next boot
  restart         Restarts all physical servers
  topology        Renders the infrastructure diagrams (nix-topology) to docs/src/topology
  buildiso-remote Spawns a buildiso shell on the iso-runner builder
  buildiso-local  Spawns a local buildiso shell to build to ./buildiso (needs Docker)
```
