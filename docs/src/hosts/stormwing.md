# stormwing

This is one of the two main infrastructure hosts (see also: aerialis). All services and containers for stormwing are defined in `nixos/hosts/stormwing.nix` and its submodules.

## Host configuration

```nix
{{#include ../../../nixos/hosts/stormwing.nix}}
```

## Containers/services

- [chaotic-v4](chaotic-v4.md): Main Chaotic-AUR builder and repository sync container.
- [firedragon-runner](firedragon-runner.md): CI runner for building and testing the Firedragon browser.
- [github-runner](github-runner.md): GitHub Actions runner for CI/CD tasks related to Garuda Linux projects.
- [iso-runner](iso-runner.md): Dedicated builder for Garuda Linux ISO images.
- [web-front](web-front.md): Reverse proxy and web frontend for services running on stormwing.

See the respective documentation pages for up-to-date configuration and details.
