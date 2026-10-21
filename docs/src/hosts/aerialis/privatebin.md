# privatebin (aerialis)

This container runs our PrivateBin instance.

## General

The service uses the NixOS `services.privatebin` module with nginx and php-fpm.
Pastes are stored in `/var/lib/privatebin/data`, which is bind-mounted from `/data_1/containers/privatebin` on the
host and therefore included in the offsite system backups.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/privatebin.nix}}
```
