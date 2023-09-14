# forum

## General

In here, we only have Docker set up and use the traditional way of installing Discourse to `/var/discourse`. Since own scripts are provided to handle the container, not much is to be seen here.

## Links

- [Discourse Docker](https://github.com/discourse/discourse_docker)

## Nix expression

```nix
{{#include ../../../nixos/hosts/forum.nix}}
```
