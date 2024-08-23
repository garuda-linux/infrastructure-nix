# web-front

## General

This container is used as a reverse proxy for all of our public facing services.
It also contains a Cloudflared instance,
which a few services are only being exposed to, instead of being reverse proxied by Nginx itself.

## Nix expression

```nix
{{#include ../../../nixos/hosts/web-front.nix}}
```
