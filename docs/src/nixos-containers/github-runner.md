# github-runner

## General

With this container, we provide a GitHub runner. This container does **not** have the regular Garuda configurations because it is considered untrusted.
Access needs to happen by running `nixos-container root-login` on `immortalis` ([click me](http://docs.garudalinux.net/hosts/immortalis.html#connecting-to-the-server)).

## Nix expression

```nix
{{#include ../../../nixos/hosts/github-runner.nix}}
```
