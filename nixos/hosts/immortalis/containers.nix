{ garuda-lib
, lib
, ...
}:
let
  chaotic_mounts = {
    "gitconfig" = {
      hostPath = "/root/.gitconfig";
      mountPoint = "/root/.gitconfig";
    };
    "keyring" = {
      hostPath = "/root/.gnupg";
      isReadOnly = false;
      mountPoint = "/root/.gnupg";
    };
    "pacman" = {
      hostPath = "/data_2/chaotic/pkg";
      isReadOnly = false;
      mountPoint = "/var/cache/pacman/pkg";
    };
    "chaotic-sources" = {
      hostPath = "/data_2/chaotic/sources";
      isReadOnly = false;
      mountPoint = "/var/cache/chaotic/sources";
    };
    "chaotic-cc" = {
      hostPath = "/data_2/chaotic/cc";
      isReadOnly = false;
      mountPoint = "/var/cache/chaotic/cc";
    };
    "telegram-send-group" = {
      hostPath = "/var/garuda/secrets/chaotic/telegram-send-group";
      mountPoint = "/root/.config/telegram-send-group.conf";
    };
    "telegram-send-log" = {
      hostPath = "/var/garuda/secrets/chaotic/telegram-send-log";
      mountPoint = "/root/.config/telegram-send-log.conf";
    };
  };
in
{
  # Custom systemd nspawn container configurations
  services.garuda-nspawn = {
    bridgeInterface = "br0";
    hostInterface = "eth0";
    hostIp = "10.0.5.1";
    dockerCache = "/data_1/dockercache/";
    containers = {
      chaotic-v4 = {
        config = import ../chaotic-v4.nix;
        extraOptions = {
          bindMounts = {
            "chaotic" = {
              hostPath = "/data_1/containers/chaotic-v4/chaotic";
              isReadOnly = false;
              mountPoint = "/var/garuda/docker-compose-runner/chaotic-v4";
            };
            "chaotic-v4" = {
              hostPath = "/data_2/chaotic-v4/";
              isReadOnly = false;
              mountPoint = "/srv/http/repos";
            };
            "grafana" = {
              hostPath = "/data_1/containers/chaotic-v4/grafana";
              isReadOnly = false;
              mountPoint = "/var/lib/grafana";
            };
            "prometheus" = {
              hostPath = "/data_1/containers/chaotic-v4/prometheus";
              isReadOnly = false;
              mountPoint = "/var/lib/prometheus2";
            };
            "redis" = {
              hostPath = "/data_1/containers/chaotic-v4/redis";
              isReadOnly = false;
              mountPoint = "/var/lib/redis-chaotic/";
            };
          };
          enableTun = true;
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.140";
        needsDocker = true;
      };
      docker = {
        config = import ../docker.nix;
        extraOptions = {
          bindMounts = {
            "compose" = {
              hostPath = "/data_1/containers/docker/";
              isReadOnly = false;
              mountPoint = "/var/garuda/docker-compose-runner/all-in-one";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 225;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.100";
        needsDocker = true;
      };
      docker-proxied = {
        config = import ../docker-proxied.nix;
        extraOptions = {
          bindMounts = {
            "compose" = {
              hostPath = "/data_1/containers/docker-proxied/";
              isReadOnly = false;
              mountPoint = "/var/garuda/docker-compose-runner/proxied";
            };
          };
        };
        ipAddress = "10.0.5.110";
        needsDocker = true;
      };
      forum = {
        config = import ../forum.nix;
        extraOptions = {
          bindMounts = {
            "forum" = {
              hostPath = "/data_1/containers/forum/";
              isReadOnly = false;
              mountPoint = "/var/discourse";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 224;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.70";
        needsDocker = true;
      };
      github-runner = {
        config = import ../github-runner.nix;
        defaults = false;
        extraOptions = {
          bindMounts = {
            "token" = {
              hostPath = garuda-lib.secrets.docker-compose.github-runner;
              isReadOnly = true;
              mountPoint = "/var/garuda/secrets/github-runner.env";
            };
            "gitlab-config" = {
              hostPath = "/data_1/containers/github-runner/gitlab-runner";
              isReadOnly = false;
              mountPoint = "/etc/gitlab-runner";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 230;
              protocol = "tcp";
            }
          ];
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.130";
        needsDocker = true;
      };
      iso-runner = {
        config = import ../iso-runner.nix;
        extraOptions = {
          bindMounts = {
            "iso" = {
              hostPath = "/data_2/iso/";
              isReadOnly = false;
              mountPoint = "/var/garuda/buildiso";
            };
            "pacman" = {
              hostPath = "/data_2/chaotic/pkg";
              isReadOnly = false;
              mountPoint = "/var/cache/pacman/pkg";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 227;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.40";
        needsDocker = true;
      };
      lemmy = {
        config = import ../lemmy.nix;
        extraOptions = {
          bindMounts = {
            "pict-rs" = {
              hostPath = "/data_1/containers/lemmy/pict-rs";
              isReadOnly = false;
              mountPoint = "/var/lib/pict-rs";
            };
          };
        };
        ipAddress = "10.0.5.120";
      };
      mastodon = {
        config = import ../mastodon.nix;
        extraOptions = {
          bindMounts = {
            "mastodon" = {
              hostPath = "/data_1/containers/mastodon/mastodon";
              isReadOnly = false;
              mountPoint = "/var/lib/mastodon";
            };
          };
          bindMounts = {
            "redis" = {
              hostPath = "/data_1/containers/mastodon/redis/";
              isReadOnly = false;
              mountPoint = "/var/lib/redis-mastodon";
            };
          };
        };
        ipAddress = "10.0.5.80";
      };
      mongodb = {
        config = import ../mongodb.nix;
        extraOptions = {
          bindMounts = {
            "cert" = {
              hostPath = "/var/garuda/secrets/mongodb";
              isReadOnly = true;
              mountPoint = "/etc/ssl/mongodb";
            };
            "data" = {
              hostPath = "/data_1/containers/mongodb/data";
              isReadOnly = false;
              mountPoint = "/var/db/mongodb";
            };
          };
          forwardPorts = [
            {
              containerPort = 27017;
              hostPort = 27017;
              protocol = "tcp";
            }
          ];
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.60";
      };
      postgres = {
        config = import ../postgres.nix;
        extraOptions = {
          bindMounts = {
            "postgres_backup" = {
              hostPath = "/data_1/containers/postgres/backup";
              isReadOnly = false;
              mountPoint = "/var/garuda/backups/postgres";
            };
            "data" = {
              hostPath = "/data_1/containers/postgres/data";
              isReadOnly = false;
              mountPoint = "/var/lib/postgresql";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 229;
              protocol = "tcp";
            }
          ];
          ephemeral = lib.mkForce true;
        };
        ipAddress = "10.0.5.50";
      };
      temeraire = {
        config = import ../temeraire.nix;
        extraOptions = {
          bindMounts = lib.mkMerge [{
            "chaotic-v4" = {
              hostPath = "/data_2/chaotic-v4/chaotic-aur";
              isReadOnly = false;
              mountPoint = "/srv/http/chaotic-v4";
            };
            "garuda" = {
              hostPath = "/data_2/chaotic-v4/garuda";
              isReadOnly = false;
              mountPoint = "/srv/http/repos/garuda";
            };
            "chaotic" = {
              hostPath = "/data_2/chaotic-aur";
              isReadOnly = false;
              mountPoint = "/srv/http/repos";
            };
            "iso" = {
              hostPath = "/data_2/iso/";
              isReadOnly = false;
              mountPoint = "/var/garuda/buildiso";
            };
            "iso-builds" = {
              hostPath = "/data_2/iso/iso";
              isReadOnly = false;
              mountPoint = "/srv/http/iso";
            };
            "repoctl" = {
              hostPath = "/data_2/containers/temeraire/chaotic-repoctl.toml";
              isReadOnly = false;
              mountPoint = "/usr/local/etc/chaotic-repoctl.toml";
            };
            "syncthing" = {
              hostPath = "/data_2/containers/temeraire/syncthing";
              isReadOnly = false;
              mountPoint = "/var/lib/syncthing";
            };
          }
            chaotic_mounts];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 22;
              protocol = "tcp";
            }
            {
              containerPort = 873;
              hostPort = 873;
              protocol = "tcp";
            }
            {
              containerPort = 21027;
              hostPort = 21027;
              protocol = "udp";
            }
            {
              containerPort = 22000;
              hostPort = 22000;
              protocol = "tcp";
            }
            {
              containerPort = 22000;
              hostPort = 22000;
              protocol = "udp";
            }
          ];
          tmpfs = [ "/tmp:size=25G" ];
        };
        ipAddress = "10.0.5.20";
      };
      web-front = {
        config = import ../web-front.nix;
        extraOptions = {
          bindMounts = {
            "nginx" = {
              hostPath = "/var/log/nginx";
              isReadOnly = false;
              mountPoint = "/var/log/nginx";
            };
          };
          forwardPorts = [{
            containerPort = 22;
            hostPort = 222;
            protocol = "tcp";
          }];
        };
        ipAddress = "10.0.5.10";
      };
    };
  };

  # Set some sanity limits & make sure postgres is started before other containers
  systemd.services = {
    "container@docker".requires = [ "container@postgres.service" ];
    "container@docker-proxied".requires = [ "container@postgres.service" ];
    "container@lemmy".requires = [ "container@postgres.service" ];
    "container@mastodon".requires = [ "container@postgres.service" ];
    "container@postgres" = {
      before = [
        "container@docker-proxied.service"
        "container@docker.service"
        "container@lemmy.service"
        "container@mastodon.service"
      ];
    };
  };
}
