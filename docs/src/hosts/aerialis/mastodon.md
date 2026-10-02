# mastodon (aerialis)

This container runs the Mastodon social network instance for Garuda Linux, providing decentralized microblogging.

## Restarting containers

The Docker stack can be restarted via the following command:

```bash
sudo systemctl restart compose-runner-mastodon
```

## Nix expression

Configuration for the `mastodon` container on aerialis.

```nix
{{#include ../../../../nixos/hosts/aerialis/mastodon.nix}}
```
