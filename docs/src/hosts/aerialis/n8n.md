# n8n (aerialis)

This container runs our n8n workflow automation instance.

## General

n8n is used to automate recurring tasks and glue our services together. The editor and API are reachable at
[n8n.garudalinux.net](https://n8n.garudalinux.net), while incoming webhooks use the separate
[n8n-webhooks.garudalinux.net](https://n8n-webhooks.garudalinux.net) host, which only proxies `/webhook` and returns
`404` for everything else. Both hosts are proxied by the [aerialis web-front](web-front.md).

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/n8n.nix}}
```
