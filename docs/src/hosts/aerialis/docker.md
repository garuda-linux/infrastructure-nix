# docker (aerialis)

This container runs general-purpose Docker workloads for services that are not packaged natively in NixOS.

## General

This container is used to run regular Docker containers.
Recently, the `compose-runner` module has been replaced by native Nix expressions.

## Nextcloud AIO

This container also runs a Nextcloud AIO master container, which administrates its containers by itself.
Consult its [extensive documentation for more information](https://github.com/nextcloud/docker).
Since this container requires a Nextcloud volume at a fixed place, without being able to change it, it is not
included in the regular data directory.

Instead, backups are regularly performed via the inbuilt backup function in the admin interface.
They can be found at `/var/garuda/compose-runner/docker/nextcloud-aio`
and are included in the offsite system backups.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/docker.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/docker/compose.yml}}
```
