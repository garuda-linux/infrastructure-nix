# chaotic-backend (aerialis)

This container provides backend services for Chaotic-AUR, including API endpoints and job processing for the repository.

## Restarting containers

The Docker stack can be restarted via the following command:

```bash
sudo systemctl restart compose-runner-chaotic-backend
```

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/chaotic-backend.nix}}
```

### Docker containers

```yaml
{{#include ../../../../compose/chaotic-backend/compose.yml}}
```
