# github-runner (stormwing)

This container is a GitHub Actions runner for CI/CD tasks related to Garuda Linux projects.

## General

With this container, we provide a native NixOS GitHub runner (`services.github-runners`) as well as a GitLab runner. This container does **not**
have the regular Garuda configurations because it is considered untrusted.
Access needs to happen by running `nixos-container root-login`
on [stormwing](../stormwing.md).

## Restarting containers

This can happen via the following commands:

```bash
sudo systemctl restart github-runner-stormwing-nixos
sudo systemctl restart compose-runner-gitlab-runner
```

Watchtower additionally keeps the GitLab runner container up to date.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/github-runner.nix}}
```

### GitHub runner (native NixOS)

Builds go through the host's Nix daemon (the container bind-mounts its socket), so daemon-side settings such as
`system-features` live in [stormwing](../stormwing.md)'s `nix.settings`.

This runner is only meant to run trusted code. nyx's `check-pr-trust` action allows checking out a fork PR's head
only for collaborators, members, owners or users with write access, or when a maintainer added the `safe-to-test`
label. For any other fork PR, `actions/checkout` refuses the checkout before Nix runs anything. Note that the label
stays on the PR, so commits pushed after labelling are built as well.

```nix
{{#include ../../../../nixos/hosts/stormwing/github-runner/nixos-runner.nix}}
```

### Docker containers (GitLab)

```yaml
{{#include ../../../../compose/gitlab-runner/compose.yml}}
```
