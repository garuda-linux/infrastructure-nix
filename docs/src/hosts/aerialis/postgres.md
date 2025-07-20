# postgres (aerialis)

This container provides PostgreSQL database services for other containers and applications on aerialis.

## General

This container houses our Postgres database. Multiple services access it:

- Mastodon
- Matrix
- Matrix bridges
- WikiJs

## Admin interface

The admin interface powered by Pgadmin can be accessed [here](https://pgadmin.garudalinux.net).
Authentication happens via Cloudflare Access.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/postgres.nix}}
```
