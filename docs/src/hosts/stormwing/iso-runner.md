# iso-runner (stormwing)

This container is a dedicated builder for Garuda Linux ISO images, providing a reproducible build environment.

## General

This container is used to build our ISO via a Docker container.
It has been used to provide a GitHub runner as well,
though this one got moved to its [own container](github-runner.md) recently.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/iso-runner.nix}}
```
