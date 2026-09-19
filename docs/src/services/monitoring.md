# Monitoring

Our monitoring stack is self-hosted and lives in `nixos/services/monitoring`. It replaced the previous Netdata setup,
which kept only a few GB per host and offered no central alerting.

## Components

| Component             | Purpose                             | Port  |
| --------------------- | ----------------------------------- | ----- |
| Prometheus            | Metric storage and alert evaluation | 9090  |
| Alertmanager          | Alert routing (Telegram)            | 9093  |
| Grafana               | Dashboards                          | 3010  |
| Loki                  | Log storage                         | 3030  |
| node_exporter         | Host and container metrics          | 3021  |
| Fluent Bit            | Ships container/host logs to Loki   | -     |
| smartctl_exporter     | Disk health                         | 9633  |
| borgmatic_exporter    | Backup age, size and archive count  | 9996  |
| nginx_exporter        | Web frontend metrics                | 9113  |
| redis_exporter        | Chaotic-AUR Redis                   | 9121  |
| postfix_exporter      | Mail queue and delivery             | 9154  |
| dovecot (OpenMetrics) | Mail auth/IMAP/delivery metrics     | 9900  |
| GitLab runner metrics | CI runner                           | 9252  |
| cloudflared metrics   | Tunnel metrics                      | 20241 |

Everything runs in the `monitoring` container on aerialis (`10.0.5.100`). Hosts and containers opt in with
`garuda.monitoring`; the port numbers above are all defined once in `garuda-lib.monitoring.ports`.

Not every endpoint belongs to a dedicated exporter: Dovecot is scraped through its built-in stats listener, which
serves OpenMetrics on port 9900. Endpoints like this are declared with
`garuda.monitoring.prometheus.applicationTargets`, which also covers the postfix and redis exporters.

Prometheus retention is bounded by `garuda.monitoring.prometheus.retentionTime` and `retentionSize`.
Loki is bounded by `garuda.monitoring.loki.retentionPeriod`.

## How the pieces reach each other

Both hosts run their own `10.0.5.0/24` container bridge, so the monitoring container cannot reach stormwing's
containers at all. Stormwing therefore publishes them on its own Tailnet IP:

- each stormwing container's node_exporter is proxied on `31000 + last octet of the container IP`
  (`garuda-lib.monitoring.stormwingNodeProxies`)
- the GitLab runner and web-front cloudflared metrics are proxied on 39252 and 32041 respectively
  (`stormwingServiceProxies`)
- stormwing container logs are shipped to the bridge address and relayed by the `loki-relay` unit to
  `aerialis:3030`, where `loki-tailnet-proxy` forwards them into the monitoring container

The Chaotic-AUR mirrors are scraped over the Tailnet using MagicDNS short names, which is why the monitoring
container runs its own tailscaled instead of going through a proxy on the host.

## Alerting

Alert rules live in `nixos/services/monitoring/prometheus-rules/` (node-exporter, nginx-exporter, postgres-exporter,
smartctl-exporter, borgmatic and self-monitoring rules). Alertmanager delivers firing and resolved alerts to Telegram
as of right now. It can of course be extended to other channels as well.

## Adding a host or container

Set `garuda.monitoring` on the host or container. `garuda-lib.mkMonitoring` also adds the units to the the MOTD and
into Fluent Bit's log collection:

```nix
garuda = garuda-lib.mkMonitoring {
  host = "aerialis";
  units = [ "nginx.service" ];
  exporters = [ "nginxExporter" ];
};
```

`exporters` adds exporters on top of the always-enabled node_exporter. `hostInfo = true` additionally exports NixOS
build and version information, which feeds the "Host fleet" panel, and is only set on the two hosts themselves.
