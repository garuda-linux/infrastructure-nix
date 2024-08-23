## garuda-build (Legacy Fosshost VPS)

### General

This server is a legacy, still up Fosshost VPS. Fosshost itself ceased to be quite a while ago,
but this server is still up for some reason.
Since we can't be sure how long it will stay up, we don't want to put anything important on it.
Therefore, its sole purpose is running a disposable build environment for the Chaotic-AUR infra 4.0.

### Host-specific tasks

- Restarting the Docker stack:
  - `sudo systemctl restart docker-compose-chaotic-v4-builder-root`
  - alternatively: `sudo chaotic-restart`

### Nix expression

```nix
{{#include ../../../nixos/hosts/garuda-build.nix}}
```

### Docker containers

```nix
{{#include ../../../nixos/hosts/garuda-build/docker-compose.nix}}
```
