# chaotic-v4 (stormwing)

This container is the main Chaotic-AUR builder and repository sync node, responsible for building and distributing packages.

## General

This is the nspawn container used to run Chaotic-AUR's new build system, `infra 4.0`.

Restarting the Docker stack, in case it is needed, can happen via `sudo chaotic-restart`.
For information on how to use the new build system, please refer to the [documentation](../services/chaotic-4.0.md).

In general, manual intervention should not be needed,
as the system is designed to be fully automated via GitLab CI or GitHub actions.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/chaotic-v4.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/chaotic-v4/compose.yml}}
```
