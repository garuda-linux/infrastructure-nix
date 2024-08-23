# mongodb

## General

This container contains our MongoDB instance, which is primarily used for storing Chaotic-AUR router metrics.

The instance requires the use of TLS, but can be accessed without presenting a valid client certificate,
so that the Heroku instance the router runs on can access it easier.

Access happens via the regular MongoDB port, `27017` and the domain `builds.garudalinux.org`.

## Nix expression

```nix
{{#include ../../../nixos/hosts/mongodb.nix}}
```
