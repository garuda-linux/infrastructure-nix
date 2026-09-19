# gitlab-runner (stormwing)

This container runs GitLab CI runners that build our packages.

## General

Two runners are configured on it, `stormwing-nix-caching` and `stormwing-nix-dind`. Both make use of the shared Nix
cache and are allowed to use KVM, which is why the container has `/dev/kvm` passed through. The main selling point
of these is obviously the shared Nix store, which is the reason why these should in the long run be preferred over
the other Docker-based runner.

For these to pick up any builds, the tags `nix` or `nix-dind` must be added to the CI configuration.

Its metrics are exposed on port `9252` and published on stormwing's Tailnet IP for Prometheus (see
[Monitoring](../../services/monitoring.md)).

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/gitlab-runner.nix}}
```
