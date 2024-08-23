# docker-proxied

## General

Here, all of the Docker containers that need to have proxied outgoing requests are being deployed.

## Nix expression

```nix
{{#include ../../../nixos/hosts/docker-proxied.nix}}
```

### Docker containers

```nix
{{#include ../../../nixos/hosts/docker-proxied/docker-compose.nix}}
```
