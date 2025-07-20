# docker-proxied

## General

Here, all the Docker containers that need to have proxied outgoing requests are being deployed. This is mainly for privacy-focused or alternative frontends and search engines that benefit from outgoing proxying.

### Container explanations

- **whoogle**: A self-hosted, ad-free, privacy-respecting metasearch engine that proxies Google Search results.
- **searx**: SearxNG, a privacy-respecting metasearch engine aggregating results from various sources.
- **librey**: Librey, a metasearch engine with a focus on privacy and alternative search sources.
- **lingva**: Lingva Translate, a privacy-friendly alternative frontend for Google Translate.
- **redlib**: Redlib, a privacy-respecting alternative frontend for Reddit.
- **watchtower**: Automatically updates running containers to the latest image versions.
- **autoheal**: Monitors containers and restarts them if they become unhealthy (e.g., Whoogle).

## Restarting containers

This can happen via the following command:

```bash
sudo systemctl restart docker-compose-proxied-root
```

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/docker-proxied.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/docker-proxied/compose.yml}}
```
