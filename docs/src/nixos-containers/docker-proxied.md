# docker-proxied

## General

Here, all the Docker containers that need to have proxied outgoing requests are being deployed.

## Restarting containers

This can happen via the following command:

```bash
sudo systemctl restart docker-compose-proxied-root
```

## Nix expression

```nix
{{#include ../../../nixos/hosts/docker-proxied.nix}}
```

### Docker containers

```nix
{{#include ../../../nixos/hosts/docker-proxied/docker-compose.nix}}
```
