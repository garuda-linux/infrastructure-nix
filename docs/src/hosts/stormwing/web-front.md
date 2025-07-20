# web-front (stormwing)

This container acts as the reverse proxy and web frontend for services running on stormwing, handling HTTPS and routing.

## Nix expression

Configuration for the `web-front` container on stormwing.

```nix
{{#include ../../../../nixos/hosts/stormwing/web-front.nix}}
```
