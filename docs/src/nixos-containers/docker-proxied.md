# docker-proxied

## General

Here, all of the Docker containers that need to have proxied outgoing requests are being deployed.

## Nix expression

```nix
{{#include ../../../nixos/hosts/docker-proxied.nix}}
```

## Docker compose

```yaml
{{#include ../../../docker-compose/proxied/docker-compose.yml}}
```
