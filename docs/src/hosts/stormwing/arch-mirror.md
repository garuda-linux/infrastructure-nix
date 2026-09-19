# arch-mirror (stormwing)

This container mirrors the Arch Linux repositories.

## General

The `garuda-arch-mirror` service syncs the mirror from its configured upstream and serves it through nginx. Synced
packages are additionally pushed to Cloudflare R2 with rclone, so users can also fetch them from there. The mirror
directory is shared with [chaotic-v4](chaotic-v4.md), which serves it as `/srv/http/arch-mirror` as well.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/arch-mirror.nix}}
```
