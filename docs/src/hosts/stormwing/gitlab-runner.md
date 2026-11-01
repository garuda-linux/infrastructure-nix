# gitlab-runner (stormwing)

This container runs GitLab CI runners that build our packages.

## General

Two runners are configured on it, `stormwing-nix-caching` and `stormwing-nix-privileged`. Both make use of the shared
Nix cache. The main selling point of these is obviously the shared Nix store, which is the reason why these should in
the long run be preferred over the other Docker-based runner.

For these to pick up any builds, the tags `nix` or `nix-privileged` must be added to the CI configuration.

- `stormwing-nix-caching` (tag `nix`): unprivileged. Docker remaps job root to an unprivileged uid
  (`userns-remap = "dockremap"`), so jobs talk to the nix-daemon as untrusted users. No `/dev/kvm` in the job.
- `stormwing-nix-privileged` (tag `nix-privileged`): privileged, no user namespace remapping
  (`--docker-userns host`), with `/dev/kvm`. Jobs run as root. The runner is protected in GitLab, so only jobs on
  protected branches (`main`) reach it.

Builds through the nix-daemon (`nix build`, `nix flake check`) still get KVM for NixOS tests on both runners,
because the daemon runs in this container, which has `/dev/kvm` passed through. Only jobs that start QEMU or
`nixos-test-driver` themselves need the `nix-privileged` tag.

Its metrics are exposed on port `9252` and published on stormwing's Tailnet IP for Prometheus (see
[Monitoring](../../services/monitoring.md)).

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/gitlab-runner.nix}}
```
