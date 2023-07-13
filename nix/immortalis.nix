{ config
, garuda-lib
, lib
, pkgs
, sources
, ...
}:
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

  # Custom tailscale configuration
  systemd.services.tailscale-autoconnect.script = with pkgs; ''
    sleep 2
    status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
    if [ $status = "Running" ]; then # if so, then do nothing
      exit 0
    fi
    ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey} \
      --advertise-routes=10.0.5.0/24
  '';

  # Custom systemd nspawn container configurations
  services.garuda-nspawn = {
    hostIp = "10.0.5.1";
    hostInterface = "eth0";
    bridgeInterface = "br0";
    containers = {
      chaotic-kde = {
        ipAddress = "10.0.5.90";
        needsNesting = true;
        config = import ./chaotic-kde.nix;
        extraOptions = {
          bindMounts = {
            "repo" = {
              hostPath = "/data_2/containers/chaotic-kde/repo";
              mountPoint = "/srv/http/repos/chaotic-aur-kde";
              isReadOnly = false;
            };
            "chaotic-aur-kde" = {
              hostPath = "/data_2/chaotic-aur/chaotic-aur-kde";
              mountPoint = "/srv/http/repos/chaotic-aur-kde";
              isReadOnly = false;
            };
            "cache" = {
              hostPath = "/data_2/containers/chaotic-kde/cache";
              mountPoint = "/var/cache/chaotic";
              isReadOnly = false;
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 226;
              protocol = "tcp";
            }
          ];
        };
      };
      docker = {
        ipAddress = "10.0.5.20";
        needsDocker = true;
        config = import ./docker.nix;
        extraOptions = {
          bindMounts = {
            "compose" = {
              hostPath = "/data_1/containers/docker/";
              mountPoint = "/var/garuda/docker-compose-runner/all-in-one";
              isReadOnly = false;
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
      };
      forum = {
        needsDocker = true;
        ipAddress = "10.0.5.70";
        config = import ./forum.nix;
        extraOptions = {
          bindMounts = {
            "forum" = {
              hostPath = "/data_1/containers/forum/";
              mountPoint = "/var/discourse";
              isReadOnly = false;
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
      };
      mastodon = {
        ipAddress = "10.0.5.80";
        config = import ./mastodon.nix;
        extraOptions = {
          bindMounts = {
            "mastodon" = {
              hostPath = "/data_1/containers/mastodon/mastodon";
              mountPoint = "/var/lib/mastodon";
              isReadOnly = false;
            };
          };
          bindMounts = {
            "redis" = {
              hostPath = "/data_1/containers/mastodon/redis/";
              mountPoint = "/var/lib/redis-mastodon";
              isReadOnly = false;
            };
          };
        };
      };
      meshcentral = {
        ipAddress = "10.0.5.60";
        config = import ./meshcentral.nix;
        extraOptions = {
          bindMounts = {
            "meshcentral" = {
              hostPath = "/data_1/containers/meshcentral/";
              mountPoint = "/opt/meshcentral";
              isReadOnly = false;
            };
          };
        };
      };
      postgres = {
        ipAddress = "10.0.5.50";
        config = import ./postgres.nix;
        extraOptions = {
          bindMounts = {
            "postgres" = {
              hostPath = "/data_1/containers/postgres/";
              mountPoint = "/var/garuda/backups/postgres";
              isReadOnly = false;
            };
          };
        };
      };
      repo = {
        ipAddress = "10.0.5.30";
        config = import ./repo.nix;
        needsNesting = true;
        extraOptions = {
          bindMounts = {
            "garuda" = {
              hostPath = "/data_2/chaotic-aur/garuda";
              mountPoint = "/srv/http/repos/garuda";
              isReadOnly = false;
            };
            "cache" = {
              hostPath = "/data_2/containers/repo/cache";
              mountPoint = "/var/cache/chaotic";
              isReadOnly = false;
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 223;
              protocol = "tcp";
            }
          ];
        };
      };
      runner = {
        config = import ./runner.nix;
        ipAddress = "10.0.5.40";
        needsDocker = true;
      };
      temeraire = {
        ipAddress = "10.0.5.20";
        config = import ./temeraire.nix;
        needsNesting = true;
        extraOptions = {
          bindMounts = {
            "garuda" = {
              hostPath = "/data_2/chaotic-aur";
              mountPoint = "/srv/http/repos";
              isReadOnly = false;
            };
            "cache" = {
              hostPath = "/data_2/containers/temeraire/cache";
              mountPoint = "/var/cache/chaotic";
              isReadOnly = false;
            };
          };
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 22;
              protocol = "tcp";
            }
            {
              containerPort = config.services.rsyncd.port;
              hostPort = config.services.rsyncd.port;
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
      };
      web-front = {
        ipAddress = "10.0.5.10";
        config = import ./web-front.nix;
        extraOptions = {
          bindMounts = {
            "nginx" = {
              hostPath = "/var/log/nginx";
              mountPoint = "/var/log/nginx";
              isReadOnly = false;
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
          ];
        };
      };
    };
  };

  garuda-lib.unifiedUID = true;
  system.stateVersion = "23.05";
}

