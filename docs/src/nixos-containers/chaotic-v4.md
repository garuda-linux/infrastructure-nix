# chaotic-v4

## General

This is the nspawn container used to run Chaotic-AUR's new build system, `infra 4.0`.

## Nix expression

```nix
{{#include ../../../nixos/hosts/chaotic-v4.nix}}
```

### Docker containers

```nix
{{#include ../../../nixos/hosts/chaotic-v4/docker-compose.nix}}
```
