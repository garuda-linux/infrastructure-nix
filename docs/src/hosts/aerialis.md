# aerialis

This is one of the two main infrastructure hosts (see also: stormwing). All services and containers for aerialis are defined in `nixos/hosts/aerialis.nix` and its submodules.

## Host configuration

```nix
{{#include ../../../nixos/hosts/aerialis.nix}}
```

## Shared host configuration

The disk layout, SSH configuration, container bridge (`br0`) and impermanence are shared with stormwing and live in
`nixos/modules/special/newgen.nix`. Hardware-specific settings (kernel, microcode, SMT, smartd) come from
`nixos/modules/special/hetzner-ex44.nix`.

```nix
{{#include ../../../nixos/modules/special/newgen.nix}}
```

## Containers/services

- [chaotic-backend](./aerialis/chaotic-backend.md): Backend services for Chaotic-AUR, including API and job processing.
- [docker](./aerialis/docker.md): General-purpose Docker container runner for services not packaged in Nix.
- [docker-proxied](./aerialis/docker-proxied.md): Docker runner for services that require special proxying or network setup.
- [forum](./aerialis/forum.md): Hosts the Discourse forum for the Garuda Linux community.
- [mail](./aerialis/mail.md): Handles mail-related services and relays for the infrastructure.
- [mastodon](./aerialis/mastodon.md): Runs the Mastodon social network instance.
- [monitoring](./aerialis/monitoring.md): Runs the monitoring stack (Prometheus, Grafana, Loki, Alertmanager).
- [n8n](./aerialis/n8n.md): Workflow automation and incoming webhooks.
- [postgres](./aerialis/postgres.md): Provides PostgreSQL database services for other containers.
- [web-front](./aerialis/web-front.md): Acts as the main reverse proxy and web frontend for hosted services.

See the respective documentation pages for up-to-date configuration and details.
