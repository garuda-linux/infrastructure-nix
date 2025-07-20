# github-runner (stormwing)

This container is a GitHub Actions runner for CI/CD tasks related to Garuda Linux projects.

## General

With this container, we provide a GitHub runner as well as (more recently), a GitLab runner. This container does **not**
have the regular Garuda configurations because it is considered untrusted.
Access needs to happen by running `nixos-container root-login`
on `immortalis` ([click me](http://docs.garudalinux.net/hosts/immortalis.html#connecting-to-the-server)).

## Restarting containers

This can happen via the following command:

```bash
sudo systemctl restart docker-compose-gitlab-runner-root
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
{{#include ../../../../compose/github-runner/compose.yml}}
```
