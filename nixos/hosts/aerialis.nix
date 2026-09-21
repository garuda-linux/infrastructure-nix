{
  garuda-lib,
  ...
}:
let
  mon = garuda-lib.monitoring;
in
{
  imports = [
    ../modules
    ./../modules/special/hetzner-ex44.nix
  ];

  garuda =
    garuda-lib.mkMonitoring {
      host = "aerialis";
      hostInfo = true;
      units = [
        "borgmatic.service"
        "borgmatic.timer"
        "sshd.service"
        "tailscaled.service"
      ];
      exporters = [
        "smartctlExporter"
        "borgmaticExporter"
      ];
    }
    // {
      backup.borgmatic = {
        enable = true;
        name = "aerialis";
        user = "u342919";
        host = "u342919.your-storagebox.de";
        port = 23;
        label = "hetzner";
        sshKeySecret = "backup/ssh_aerialis";
        knownHosts = [
          {
            name = "storagebox-ed25519";
            publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs"; # pragma: allowlist secret
          }
          {
            name = "storagebox-rsa";
            publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw=="; # pragma: allowlist secret
          }
          {
            name = "storagebox-ecdsa";
            publicKey = "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAGK0po6usux4Qv2d8zKZN1dDvbWjxKkGsx7XwFdSUCnF19Q8psHEUWR7C/LtSQ5crU/g+tQVRBtSgoUcE8T+FWp5wBxKvWG2X9gD+s9/4zRmDeSJR77W6gSA/+hpOZoSE+4KgNdnbYSNtbZH/dN74EG7GLb/gcIpbUUzPNXpfKl7mQitw=="; # pragma: allowlist secret
          }
        ];
        sourceDirectories = [
          "/data_1/containers"
          "/data_1/persistent/etc/ssh"
          "/data_2/backup/nextcloud-aio/"
          "/data_2/containers/chaotic-backend/chaotic/database"
          "/data_2/containers/mastodon"
          "/data_2/containers/postgres"
        ];
        excludePatterns = [
          "/data_1/dockercache"
          "/data_1/dockerdata"
        ];
      };
    };

  networking = {
    defaultGateway = "157.180.57.65";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "aerialis";
    interfaces."eth0".ipv4.addresses = [
      {
        address = "157.180.57.100";
        prefixLength = 26;
      }
    ];
    nat.forwardPorts = [
      (garuda-lib.mkNatForward {
        sourcePort = 80;
        destination = "10.0.5.10:80";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 443;
        destination = "10.0.5.10:443";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 443;
        destination = "10.0.5.10:443";
        proto = "udp";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 465;
        destination = "10.0.5.80:465";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 993;
        destination = "10.0.5.80:993";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 25;
        destination = "10.0.5.80:25";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 4190;
        destination = "10.0.5.80:4190";
      })
    ];
  };

  # Can't set this inside the containers
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  services.garuda-nspawn = {
    dockerCache = "/data_1/dockercache/";

    containers = garuda-lib.mkContainers {
      dir = ./aerialis;
      ips = mon.aerialisContainers;
      containers = {
        chaotic-backend = {
          mounts = [
            {
              name = "chaotic";
              hostPath = "/data_2/containers/chaotic-backend/chaotic";
              mountPoint = "/var/garuda/compose-runner/chaotic-backend";
            }
            {
              name = "chaotic-redis";
              hostPath = "/data_2/containers/chaotic-backend/redis";
              mountPoint = "/var/lib/redis-chaotic";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 270;
            }
          ];
          nspawn = {
            enableTun = true;
          };
          needsDocker = true;
        };

        docker = {
          mounts = [
            {
              name = "compose";
              hostPath = "/data_1/containers/docker/";
              mountPoint = "/var/garuda/compose-runner/docker";
            }
            {
              name = "nextcloud-local-backup";
              hostPath = "/data_2/backup/nextcloud-aio";
              mountPoint = "/var/garuda/backups/nextcloud";
            }
          ];
          needsDocker = true;
        };

        docker-proxied = {
          mounts = [
            {
              name = "compose";
              hostPath = "/data_1/containers/docker-proxied/";
              mountPoint = "/var/garuda/compose-runner/docker-proxied";
            }
          ];
          needsDocker = true;
        };

        forum = {
          mounts = [
            {
              name = "forum";
              hostPath = "/data_1/containers/forum/";
              mountPoint = "/var/discourse";
            }
          ];
          needsDocker = true;
        };

        mastodon = {
          mounts = [
            {
              name = "mastodon";
              hostPath = "/data_2/containers/mastodon/mastodon";
              mountPoint = "/var/lib/mastodon";
            }
            {
              name = "compose";
              hostPath = "/data_1/containers/mastodon/compose";
              mountPoint = "/var/garuda/compose-runner/mastodon";
            }
          ];
          needsDocker = true;
        };

        mail = {
          mounts = [
            {
              name = "acme";
              hostPath = "/data_2/containers/web-front/acme";
              mountPoint = "/var/lib/acme";
            }
            {
              name = "dkim";
              hostPath = "/data_1/containers/mail/dkim";
              mountPoint = "/var/dkim";
            }
            {
              name = "index";
              hostPath = "/data_1/containers/mail/index";
              mountPoint = "/var/lib/dovecot/indices";
            }
            {
              name = "rspamd";
              hostPath = "/data_1/containers/mail/rspamd";
              mountPoint = "/var/lib/redis-rspamd";
            }
            {
              name = "vmail";
              hostPath = "/data_1/containers/mail/vmail";
              mountPoint = "/var/vmail";
            }
          ];
        };

        postgres = {
          mounts = [
            {
              name = "data";
              hostPath = "/data_1/containers/postgres/data";
              mountPoint = "/var/lib/postgresql";
            }
            {
              name = "postgres_backup";
              hostPath = "/data_2/containers/postgres/backup";
              mountPoint = "/var/garuda/backups/postgres";
            }
            {
              name = "acme";
              hostPath = "/data_2/containers/web-front/acme";
              mountPoint = "/var/lib/acme";
              readOnly = true;
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 220;
            }
            { containerPort = 5432; }
          ];
        };

        web-front = {
          mounts = [
            {
              name = "acme";
              hostPath = "/data_2/containers/web-front/acme";
              mountPoint = "/var/lib/acme";
            }
            {
              name = "nginx";
              hostPath = "/data_2/containers/web-front/nginx";
              mountPoint = "/var/log/nginx";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 210;
            }
          ];
        };

        n8n = {
          mounts = [
            {
              name = "n8n";
              hostPath = "/data_1/containers/n8n/var-lib";
              mountPoint = "/var/lib";
            }
          ];
        };

        monitoring = {
          mounts = [
            {
              name = "alertmanager";
              hostPath = "/data_1/containers/monitoring/alertmanager";
              mountPoint = "/var/lib/private/alertmanager";
            }
            {
              name = "prometheus";
              hostPath = "/data_1/containers/monitoring/prometheus";
              mountPoint = "/var/lib/prometheus2";
            }
            {
              name = "grafana";
              hostPath = "/data_1/containers/monitoring/grafana";
              mountPoint = "/var/lib/grafana";
            }
            {
              name = "loki";
              hostPath = "/data_1/containers/monitoring/loki";
              mountPoint = "/var/lib/loki";
            }
            {
              name = "tailscale";
              hostPath = "/data_1/containers/monitoring/tailscale";
              mountPoint = "/var/lib/tailscale";
            }
          ];
          nspawn = {
            enableTun = true;
          };
        };
      };
    };
  };

  systemd.services =
    garuda-lib.mkContainerOrdering {
      root = "postgres";
      containers = [
        "docker-proxied"
        "docker"
        "mastodon"
        "chaotic-backend"
      ];
    }
    // {
      loki-tailnet-proxy = garuda-lib.mkTunnel {
        bind = mon.tailnetIPs.aerialis;
        listen = mon.ports.loki;
        target = "${mon.loki.containerAddress}:${toString mon.ports.loki}";
        after = [
          "tailscaled.service"
          "container@monitoring.service"
        ];
        wants = [ "container@monitoring.service" ];
        description = "Expose Loki to Tailnet only";
      };
    };

  networking.firewall.interfaces."${mon.bridge.interface}".allowedTCPPorts = [
    mon.ports.nodeExporter
    mon.ports.smartctlExporter
    mon.ports.borgmaticExporter
  ];
}
