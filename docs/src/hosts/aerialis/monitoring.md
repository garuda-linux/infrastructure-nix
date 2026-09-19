# monitoring (aerialis)

This container runs our complete monitoring stack: Prometheus, Alertmanager, Grafana and Loki, together with the
exporters that feed them.

## General

It is the counterpart to the agents that the hosts and containers run themselves (node_exporter and Fluent Bit). Unlike
the other containers it runs its own tailscaled, so that Prometheus can scrape the Chaotic-AUR mirrors over the Tailnet 
using MagicDNS names, and it listens on `10.0.5.100` on the host's container bridge.

See [Monitoring](../../services/monitoring.md) for the full picture, including how the stormwing containers are reached
and how alerts are routed.

## Nix expression

```nix
{{#include ../../../../nixos/hosts/aerialis/monitoring.nix}}
```
