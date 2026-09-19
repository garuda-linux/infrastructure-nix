# stormwing

This is one of the two main infrastructure hosts (see also: aerialis). All services and containers for stormwing are defined in `nixos/hosts/stormwing.nix` and its submodules.

## Host configuration

```nix
{{#include ../../../nixos/hosts/stormwing.nix}}
```

## Shared host configuration

The disk layout, SSH configuration, container bridge (`br0`) and impermanence are shared with aerialis and live in
`nixos/modules/special/newgen.nix`. Hardware-specific settings (kernel, microcode, SMT, smartd) come from
`nixos/modules/special/hetzner-ex44.nix`.

```nix
{{#include ../../../nixos/modules/special/newgen.nix}}
```

## Containers/services

- [arch-mirror](arch-mirror.md): Mirrors the Arch Linux repositories and pushes them to Cloudflare R2.
- [chaotic-v4](chaotic-v4.md): Main Chaotic-AUR builder and repository sync container.
- [firedragon-runner](firedragon-runner.md): CI runner for building and testing the Firedragon browser.
- [github-runner](github-runner.md): GitHub Actions runner for CI/CD tasks related to Garuda Linux projects.
- [gitlab-runner](gitlab-runner.md): GitLab CI runners for building our packages.
- [iso-runner](iso-runner.md): Dedicated builder for Garuda Linux ISO images.
- [web-front](web-front.md): Reverse proxy and web frontend for services running on stormwing.

See the respective documentation pages for up-to-date configuration and details.
