# firedragon-runner (stormwing)

This container is a CI runner for building and testing the Firedragon browser in an isolated environment. 
It is separate from the other GitLab runner to ensure only one build runs at a time, while the others can run in parallel.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/stormwing/firedragon-runner.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/firedragon-runner/compose.yml}}
```
