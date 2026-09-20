[
  {
    name = "Mail";
    rules = [
      {
        alert = "PostfixExporterDown";
        expr = "up{job=\"app-postfix\"} == 0";
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Postfix exporter down ({{ $labels.instance }})";
          description = "Postfix prometheus exporter is down\n  Host: {{ $labels.instance }}\n  Job: {{ $labels.job }}";
        };
      }
      {
        alert = "PostfixDeferredBacklog";
        expr = "postfix_showq_queue_depth{queue=\"deferred\"} > 50";
        for = "15m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Postfix deferred queue backing up ({{ $labels.instance }})";
          description = "More than 50 messages stuck in the deferred queue for 15 minutes\n  Host: {{ $labels.instance }}\n  Deferred: {{ $value }}";
        };
      }
      {
        alert = "PostfixQueueStuck";
        expr = "histogram_quantile(0.9, rate(postfix_showq_message_age_seconds_bucket[15m])) > 3600";
        for = "15m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Mail stuck in Postfix queue ({{ $labels.instance }})";
          description = "p90 queued message age exceeds 1 hour\n  Host: {{ $labels.instance }}\n  Age: {{ $value | humanizeDuration }}";
        };
      }
      {
        alert = "PostfixSASLBruteForce";
        expr = "sum(rate(postfix_smtpd_sasl_authentication_failures_total[5m])) > 0.1";
        for = "10m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Possible SASL brute force ({{ $labels.instance }})";
          description = "Sustained SASL authentication failures\n  Host: {{ $labels.instance }}\n  Rate: {{ $value }} failures/s";
        };
      }
      {
        alert = "RspamdSpamSpike";
        expr = "100 * sum(rate(rspamd_stats_spam_count[15m])) / sum(rate(rspamd_stats_scanned[15m])) > 90";
        for = "15m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Spam flood detected";
          description = "Over 90% of scanned mail is spam for 15 minutes\n  Spam share: {{ $value }}%";
        };
      }
    ];
  }
]
