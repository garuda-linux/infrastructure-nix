# web-front (aerialis)

This container acts as the main reverse proxy and web frontend for hosted services on aerialis, handling HTTPS termination and routing.

## General

This container is used as a reverse proxy for all of our public facing services.
It also contains a Cloudflared instance,
which a few services are only being exposed to, instead of being reverse proxied by Nginx itself.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/web-front.nix}}
```
