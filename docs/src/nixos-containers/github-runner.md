# github-runner

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
{{#include ../../../nixos/hosts/github-runner.nix}}
```

### Docker containers (GitHub)

```nix
{{#include ../../../nixos/hosts/github-runner/github-compose.nix}}
```

### Docker containers (GitLab)

```nix
{{#include ../../../nixos/hosts/github-runner/gitlab-compose.nix}}
```
