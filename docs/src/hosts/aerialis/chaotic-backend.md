# chaotic-backend (aerialis)

This container provides backend services for Chaotic-AUR, including API endpoints and job processing for the repository.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/chaotic-backend.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/chaotic-backend/compose.yml}}
```
