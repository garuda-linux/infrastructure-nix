# github-runner (stormwing)

This container is a GitHub Actions runner for CI/CD tasks related to Garuda Linux projects.

## General

With this container, we provide a GitHub runner as well as (more recently), a GitLab runner. This container does **not**
have the regular Garuda configurations because it is considered untrusted.
Access needs to happen by running `nixos-container root-login`
on [stormwing](../stormwing.md).

## Restarting containers

This can happen via the following commands:

```bash
sudo systemctl restart compose-runner-github-runner
sudo systemctl restart compose-runner-gitlab-runner
```

Watchtower additionally keeps the containers up to date.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/github-runner.nix}}
```

### Docker containers (GitHub)

```yaml
{{#include ../../../../compose/github-runner/compose.yml}}
```

### Docker containers (GitLab)

```yaml
{{#include ../../../../compose/gitlab-runner/compose.yml}}
```
