[
  {
    name = "Redis";
    rules = [
      {
        alert = "RedisDown";
        expr = "up{job=\"app-redis\"} == 0";
        for = "5m";
        labels = {
          severity = "critical";
        };
        annotations = {
          summary = "Redis down ({{ $labels.instance }})";
          description = "Redis exporter reports the server is down\n  Host: {{ $labels.instance }}\n  Job: {{ $labels.job }}";
        };
      }
      {
        alert = "RedisTooManyClients";
        expr = "redis_connected_clients / redis_config_maxclients > 0.8";
        for = "10m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Redis running out of client slots ({{ $labels.instance }})";
          description = "More than 80% of maxclients connected\n  Host: {{ $labels.instance }}\n  Clients: {{ $value | humanizePercentage }} of max";
        };
      }
      {
        alert = "RedisEvictingKeys";
        expr = "sum(rate(redis_evicted_keys_total[10m])) > 0";
        for = "10m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Redis evicting keys ({{ $labels.instance }})";
          description = "Keys are being evicted, working set exceeds memory policy headroom\n  Host: {{ $labels.instance }}\n  Rate: {{ $value }} keys/s";
        };
      }
      {
        alert = "RedisBlockedClients";
        expr = "redis_blocked_clients > 5";
        for = "10m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Redis clients blocked ({{ $labels.instance }})";
          description = "Clients blocked on BLPOP/BRPOP or similar, possible slow consumer\n  Host: {{ $labels.instance }}\n  Blocked: {{ $value }}";
        };
      }
      {
        alert = "RedisHighFragRatio";
        expr = "redis_mem_fragmentation_ratio > 1.5";
        for = "15m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Redis memory fragmentation high ({{ $labels.instance }})";
          description = "Fragmentation ratio above 1.5, consider a restart or activedefrag\n  Host: {{ $labels.instance }}\n  Ratio: {{ $value }}";
        };
      }
    ];
  }
]
