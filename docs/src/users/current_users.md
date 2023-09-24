# Users

These are the people who are currently allowed to use our servers.

## Admins

Admins have root access to all servers and may therefore change everything.
They are responsible for the well-being of the infrastructure and its development.

```nix
{{#include ../../../nixos/modules/users.nix:admins}}
```

## Maintainers

Maintainers have restricted access, which allows them to use `buildiso` to build new ISO files via the `iso-runner` container.

```nix
{{#include ../../../nixos/modules/users.nix:maintainers}}
```

## Chaotic-AUR maintainers

Chaotic-AUR maintainers have access to the builder containers of our infrastructure.
They may operate the repository by doing all kinds of packaging-related tasks such as adding or removing those.

```nix
{{#include ../../../nixos/modules/users.nix:chaotic-aur}}
```
