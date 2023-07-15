{ config
, garuda-lib
, lib
, pkgs
, sources
, ...
}:
let
  chaotic_mounts = {
    "pacman" = {
      hostPath = "/var/cache/pacman/pkg";
      isReadOnly = false;
      mountPoint = "/var/cache/pacman/pkg";
    };
    "telegram-send-group" = {
      hostPath = "/var/garuda/secrets/chaotic/telegram-send-group";
      mountPoint = "/root/.config/telegram-send-group.conf";
    };
    "telegram-send-log" = {
      hostPath = "/var/garuda/secrets/chaotic/telegram-send-log";
      mountPoint = "/root/.config/telegram-send-log.conf";
    };
    "keyring" = {
      hostPath = "/root/.gnupg";
      isReadOnly = false;
      mountPoint = "/root/.gnupg";
    };
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./garuda/garuda.nix
  ];

  # Boot stuff
  boot = {
    loader.systemd-boot.enable = true;
    tmp.useTmpfs = true;
  };

  # Network configuration with a bridge interface
  networking = {
    defaultGateway = "116.202.208.65";
    hostName = "immortalis";
    interfaces = {
      "eth0".ipv4.addresses = [{
        address = "116.202.208.112";
        prefixLength = 26;
      }];
    };
  };

  # OpenSSH on another port to keep Chaotic's main node working
  services.openssh.ports = [ 666 ];

  # Make use of all threads!
  security.allowSimultaneousMultithreading = true;

  # Raise limits to support many containers
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 524288;
    "fs.inotify.max_user_watches" = 524288;
    "kernel.pid_max" = 4194303;
  };

  # Improve nspawn container performance since we grant all capabilities anyway
  # https://github.com/systemd/systemd/issues/18370#issuecomment-768645418
  environment.variables.SYSTEMD_SECCOMP = "0";

  # Custom tailscale configuration to advertise our bridge's subnet route
  systemd.services.tailscale-autoconnect.script = with pkgs; ''
    sleep 2
    status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
    if [ $status = "Running" ]; then # if so, then do nothing
      exit 0
    fi
    ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey} \
      --advertise-routes=10.0.5.0/24
  '';

  # We want to have same UID's in all containers to allow sharing home directories
  garuda-lib.unifiedUID = true;

  # Custom systemd nspawn container configurations
  services.garuda-nspawn = {
    bridgeInterface = "br0";
    hostInterface = "eth0";
    hostIp = "10.0.5.1";
    dockerCache = "/data_1/dockercache/";
    containers = {
      chaotic-kde = {
        config = import ./chaotic-kde.nix;
        extraOptions = {
          bindMounts = lib.mkMerge [{
            "chaotic-aur-kde" = {
              hostPath = "/data_2/chaotic-aur/chaotic-aur-kde";
              isReadOnly = false;
              mountPoint = "/srv/http/repos/chaotic-aur-kde";
            };
          }
            chaotic_mounts];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 226;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.90";
        needsNesting = true;
      };
      docker = {
        config = import ./docker.nix;
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
            {
              containerPort = 27017;
              hostPort = 27017;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.100";
        needsDocker = true;
      };
      forum = {
        config = import ./forum.nix;
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
      runner = {
        config = import ./runner.nix;
        ipAddress = "10.0.5.40";
        needsDocker = true;
      };
      mastodon = {
        config = import ./mastodon.nix;
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
      meshcentral = {
        config = import ./meshcentral.nix;
        extraOptions = {
          bindMounts = {
            "meshcentral" = {
              hostPath = "/data_1/containers/meshcentral/";
              isReadOnly = false;
              mountPoint = "/opt/meshcentral";
            };
          };
        };
        ipAddress = "10.0.5.60";
      };
      postgres = {
        config = import ./postgres.nix;
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
        };
        ipAddress = "10.0.5.50";
      };
      repo = {
        config = import ./repo.nix;
        extraOptions = {
          bindMounts = lib.mkMerge [{
            "garuda" = {
              hostPath = "/data_2/chaotic-aur/garuda";
              isReadOnly = false;
              mountPoint = "/srv/http/repos/garuda";
            };
          }
            chaotic_mounts];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 223;
              protocol = "tcp";
            }
          ];
        };
        ipAddress = "10.0.5.30";
        needsNesting = true;
      };
      temeraire = {
        config = import ./temeraire.nix;
        extraOptions = {
          bindMounts = lib.mkMerge [{
            "garuda" = {
              hostPath = "/data_2/chaotic-aur";
              isReadOnly = false;
              mountPoint = "/srv/http/repos";
            };
            "iso" = {
              hostPath = "/data_2/iso/";
              isReadOnly = false;
              mountPoint = "/var/garuda/buildiso/";
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
        };
        ipAddress = "10.0.5.20";
        needsNesting = true;
        needsDocker = true;
      };
      web-front = {
        config = import ./web-front.nix;
        extraOptions = {
          bindMounts = {
            "acme" = {
              hostPath = "/data_1/containers/web-front/acme";
              isReadOnly = false;
              mountPoint = "/var/lib/acme";
            };
            "nginx" = {
              hostPath = "/var/log/nginx";
              isReadOnly = false;
              mountPoint = "/var/log/nginx";
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 222;
              protocol = "tcp";
            }
            {
              containerPort = 80;
              hostPort = 80;
              protocol = "tcp";
            }
            {
              containerPort = 443;
              hostPort = 443;
              protocol = "tcp";
            }
            {
              containerPort = 443;
              hostPort = 443;
              protocol = "udp";
            }
            {
              containerPort = 8448;
              hostPort = 8448;
              protocol = "tcp";
            }
          
          ];
        };
        ipAddress = "10.0.5.10";
      };
    };
  };

  # Backup configurations to Hetzner storage box
  programs.ssh.macs = [ "hmac-sha2-512" ];
  services.borgbackup.jobs = {
    backupToHetzner = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_immortalis -p 23";
      };
      paths = [ "/data_1" "/data_2" ];
      prune.keep = {
        within = "1d";
        daily = 5;
        weekly = 2;
        monthly = 1;
      };
      repo = "u342919@u342919.your-storagebox.de:./immortalis";
      startAt = "daily";
    };
  };


  system.stateVersion = "23.05";
}

