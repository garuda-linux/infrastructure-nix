# postgres

## General

This container houses our Postgres database. Multiple servces access it:

- Lemmy
- Mastodon
- Matrix
- Matrix bridges
- WikiJs

## Nix expression

```nix
{{#include ../../../nixos/hosts/postgres.nix}}
```
