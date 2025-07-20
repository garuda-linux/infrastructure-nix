# aerialis

This is one of the two main infrastructure hosts (see also: stormwing). All services and containers for aerialis are defined in `nixos/hosts/aerialis.nix` and its submodules.

## Host configuration

```nix
{{#include ../../../nixos/hosts/aerialis.nix}}
```

## Containers/services

- [chaotic-backend](./aerialis/chaotic-backend.md): Backend services for Chaotic-AUR, including API and job processing.
- [docker](./aerialis/docker.md): General-purpose Docker container runner for services not packaged in Nix.
- [docker-proxied](./aerialis/docker-proxied.md): Docker runner for services that require special proxying or network setup.
- [forum](./aerialis/forum.md): Hosts the Discourse forum for the Garuda Linux community.
- [mail](./aerialis/mail.md): Handles mail-related services and relays for the infrastructure.
- [mastodon](./aerialis/mastodon.md): Runs the Mastodon social network instance.
- [postgres](./aerialis/postgres.md): Provides PostgreSQL database services for other containers.
- [web-front](./aerialis/web-front.md): Acts as the main reverse proxy and web frontend for hosted services.

See the respective documentation pages for up-to-date configuration and details.
