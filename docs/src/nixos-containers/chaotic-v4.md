# chaotic-v4

## General

This is the nspawn container used to run Chaotic-AUR's new build system, `infra 4.0`.

Restarting the Docker stack, in case it is needed, can happen via `sudo chaotic-restart`.
For information on how to use the new build system, please refer to the [documentation](../services/chaotic-4.0.md).

In general, manual intervention should not be needed,
as the system is designed to be fully automated via GitLab CI or GitHub actions.

## Nix expression

```nix
{{#include ../../../nixos/hosts/chaotic-v4.nix}}
```

### Docker containers

```nix
{{#include ../../../nixos/hosts/chaotic-v4/docker-compose.nix}}
```
