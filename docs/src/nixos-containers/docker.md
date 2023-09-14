# docker

## General

This container consists of our `docker-compose-runner` module, which deploys all Docker-based services that don't need to proxied outgoing requests. For the other ones, have a look [here](./docker-proxied.md).

## Nix expression

```nix
{{#include ../../../nixos/hosts/docker.nix}}
```

## Docker compose

```yaml
{{#include ../../../docker-compose/all-in-one/docker-compose.yml}}
```
