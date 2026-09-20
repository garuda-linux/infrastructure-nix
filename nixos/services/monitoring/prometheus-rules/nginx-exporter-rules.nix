[
  {
    name = "NginxStubStatus";
    rules = [
      {
        alert = "NginxDown";
        expr = "up{job=\"nginx\"} == 0";
        for = "1m";
        labels = {
          severity = "critical";
        };
        annotations = {
          summary = "Nginx exporter down (instance {{ $labels.instance }})";
          description = "The nginx exporter has been unreachable for more than a minute.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
        };
      }
      {
        alert = "NginxConnectionsDropped";
        expr = "sum by (instance) (rate(nginx_connections_accepted[5m]) - rate(nginx_connections_handled[5m])) > 1";
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Nginx dropping connections (instance {{ $labels.instance }})";
          description = "Accepted connections exceed handled ones: workers cannot keep up.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
        };
      }
    ];
  }
]
