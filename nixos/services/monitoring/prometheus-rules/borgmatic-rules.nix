[
  {
    name = "Borgmatic";
    rules = [
      {
        alert = "BorgmaticBackupMissed";
        expr = "time() - borg_last_backup_timestamp > 93600"; # 26 hours (accounting for delay)
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Borgmatic backup missed ({{ $labels.instance }})";
          description = "No backup for {{ $labels.repository }} in over 24 hours\n  Host: {{ $labels.instance }}\n  Repository: {{ $labels.repository }}\n  Last backup: {{ $value | humanizeDuration }} ago";
        };
      }
      {
        alert = "BorgmaticBackupStale";
        expr = "time() - borg_last_backup_timestamp > 172800"; # 48 hours
        for = "5m";
        labels = {
          severity = "critical";
        };
        annotations = {
          summary = "Borgmatic backup stale ({{ $labels.instance }})";
          description = "No backup for {{ $labels.repository }} in over 48 hours\n  Host: {{ $labels.instance }}\n  Repository: {{ $labels.repository }}\n  Last backup: {{ $value | humanizeDuration }} ago";
        };
      }
      {
        alert = "BorgmaticBackupSlow";
        expr = "borg_last_backup_duration > 10800"; # 3 hours
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Borgmatic backup slow ({{ $labels.instance }})";
          description = "Last backup for {{ $labels.repository }} took over 3 hours\n  Host: {{ $labels.instance }}\n  Duration: {{ $value | humanizeDuration }}";
        };
      }
      {
        alert = "BorgmaticRepositoryTooLarge";
        expr = "borg_total_deduplicated_compressed_size > 858993459200"; # ~800 GiB actually occupied on the storage box
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Borgmatic repository too large ({{ $labels.instance }})";
          description = "Repository {{ $labels.repository }} occupies over 800 GiB on disk\n  Host: {{ $labels.instance }}\n  Size: {{ $value | humanize1024 }}B";
        };
      }
      {
        alert = "BorgmaticRepositoryGrowingFast";
        expr = "delta(borg_total_size[7d]) > 536870912000"; # 500 GiB per week
        for = "5m";
        labels = {
          severity = "info";
        };
        annotations = {
          summary = "Borgmatic repository growing fast ({{ $labels.instance }})";
          description = "Repository {{ $labels.repository }} grew by >500GB in the last week\n  Host: {{ $labels.instance }}\n  Growth: {{ $value | humanize1024 }}B";
        };
      }
      {
        alert = "BorgmaticLowBackupCount";
        expr = "borg_total_backups < 3";
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Borgmatic low backup count ({{ $labels.instance }})";
          description = "Repository {{ $labels.repository }} has less than 3 backups\n  Host: {{ $labels.instance }}\n  Backup count: {{ $value }}";
        };
      }
      {
        alert = "BorgmaticExporterDown";
        expr = "up{job=~\".*borgmatic.*\"} == 0";
        for = "5m";
        labels = {
          severity = "warning";
        };
        annotations = {
          summary = "Borgmatic exporter down ({{ $labels.instance }})";
          description = "Borgmatic prometheus exporter is down\n  Host: {{ $labels.instance }}\n  Job: {{ $labels.job }}\n  URL: {{ $labels.__address__ }}";
        };
      }
    ];
  }
]
