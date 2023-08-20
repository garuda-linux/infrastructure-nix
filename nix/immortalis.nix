{ config
, garuda-lib
, lib
, pkgs
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
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./garuda/garuda.nix
  ];

  # Increase /tmp & /run size to make better use of RAM
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    runSize = "50%";
    tmp = {
      tmpfsSize = "95%";
      useTmpfs = true;
    };
  };

  # Network configuration with a bridge interface
  networking = {
    defaultGateway = "116.202.208.65";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "immortalis";
    interfaces = {
      "eth0" = {
        ipv4.addresses = [{
          address = "116.202.208.112";
          prefixLength = 26;
        }];
        ipv6.addresses = [
          # Random outgoing
          {
            address = "2a01:4f8:2200:30ac:8bc3:87ca:7eb3:1445";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:b3e8:3e97:b9ea:4f4c";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:3139:1040:65d2:f055";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:1c69:9c53:0801:c089";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:43ca:4c70:b3af:0713";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:c164:d4da:d822:b5c0";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:33ab:784a:d947:6fe1";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:370c:1719:6265:3137";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:c9c3:b7f6:fcc3:304e";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:5c1b:cfd5:7c0e:f2e5";
            prefixLength = 64;
          }
        ];
      };
    };
    # Specify these here to allow containers to access
    # our services from the internal network via NAT reflection
    nat.forwardPorts = [
      {
        destination = "10.0.5.10:80";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 80;
      }
      {
        destination = "10.0.5.10:443";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 443;
      }
      {
        destination = "10.0.5.10:443";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "udp";
        sourcePort = 443;
      }
      {
        destination = "10.0.5.10:8448";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 8448;
      }
    ];
    firewall.trustedInterfaces = [ "br0" ];
  };

  # OpenSSH on another port to keep Chaotic's main node working
  services.openssh.ports = [ 666 ];

  # Make use of all threads!
  security.allowSimultaneousMultithreading = true;

  # Raise limits to support many containers 
  # (from LXC's recommendedSysctlSettings)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
    "fs.inotify.max_user_watches" = 1048576;
    "kernel.dmesg_restrict" = 1;
    "kernel.keys.maxkeys" = 2000;
    "kernel.pid_max" = 4194303;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv6.neigh.default.gc_thresh3" = 8192;
  };

  # Improve nspawn container performance since we grant all capabilities anyway
  # https://github.com/systemd/systemd/issues/18370#issuecomment-768645418
  environment.variables.SYSTEMD_SECCOMP = "0";

  # Custom tailscale configuration to advertise our bridge's subnet route
  systemd.services.tailscale-autoconnect.script = with pkgs; ''
    sleep 2
    status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
    if [ $status = "Running" ]; then
      exit 0
    fi
    ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey} \
      --advertise-routes=10.0.5.0/24
  '';

  # We want to have same UID's in all containers to allow sharing home directories
  garuda-lib.unifiedUID = true;

  # Monitor a few services of the containers
  services = {
    netdata.configDir = {
      "go.d/postgres.conf" = pkgs.writeText "postgres.conf" ''
        jobs:
          - name: postgres
            dsn: 'postgres://netdata:netdata@10.0.5.50:5432/'
      '';
      "go.d/squidlog.conf" = pkgs.writeText "squidlog.conf" ''
        jobs:
          - name: squid
            path: /var/log/squid/access.log
            log_type: csv
            csv_config:
              format: '- resp_time client_address result_code resp_size req_method - - hierarchy mime_type'
      '';
      "go.d/web_log.conf" = pkgs.writeText "web_log.conf" ''
        jobs:
          - name: nginx
            path: /var/log/nginx/access.log
      '';
    };
    smartd = {
      enable = true;
      extraOptions = [ "-A /var/log/smartd/" "--interval=600" ];
    };
  };

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
      docker-proxied = {
        config = import ./docker-proxied.nix;
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
      iso-runner = {
        config = import ./iso-runner.nix;
        extraOptions = {
          bindMounts = {
            "pacman" = {
              hostPath = "/data_2/chaotic/pkg";
              isReadOnly = false;
              mountPoint = "/var/cache/pacman/pkg";
            };
          };
          forwardPorts = [{
            containerPort = 22;
            hostPort = 227;
            protocol = "tcp";
          }];
        };
        ipAddress = "10.0.5.40";
        needsDocker = true;
      };
      lemmy = {
        config = import ./lemmy.nix;
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
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 229;
              protocol = "tcp";
            }
          ];
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
              hostPath = "/var/garuda/buildiso";
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
        needsNesting = true;
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
    "container@meshcentral".requires = [ "container@postgres.service" ];
    "container@postgres" = {
      before = [
        "container@docker-proxied.service"
        "container@docker.service"
        "container@lemmy.service"
        "container@mastodon.service"
        "container@meshcentral.service"
      ];
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
      exclude = [ "/data_1/dockercache" "/data_1/dockerdata" ];
      paths = [ "/data_1" ];
      prune.keep = {
        within = "1d";
        daily = 3;
        weekly = 2;
        monthly = 2;
      };
      repo = "u342919@u342919.your-storagebox.de:./immortalis";
      startAt = "daily";
    };
  };

  # Lets build Garuda ISO here, serving is done via
  # Temeraire already - only until TNE fixes builds inside 
  # iso-runner (fails at creating efi partition)
  services = {
    garuda-iso.enable = true;
    nginx.enable = lib.mkForce false;
    rsyncd.enable = lib.mkForce false;
  };

  # A proxy server making use of our IPv6 IP addresses
  services.squid = {
    enable = true;
    extraConfig = ''
      forwarded_for delete
      dns_nameservers 2606:4700:4700::1111

      acl maybe random 1/5
      acl maybeyes random 1/2

      tcp_outgoing_address 2a01:4f8:2200:30ac:8bc3:87ca:7eb3:1445 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:b3e8:3e97:b9ea:4f4c maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:3139:1040:65d2:f055 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:1c69:9c53:0801:c089 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:43ca:4c70:b3af:0713 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:c164:d4da:d822:b5c0 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:33ab:784a:d947:6fe1 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:370c:1719:6265:3137 maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:c9c3:b7f6:fcc3:304e maybe
      tcp_outgoing_address 2a01:4f8:2200:30ac:5c1b:cfd5:7c0e:f2e5

      udp_outgoing_address 2a01:4f8:2200:30ac:8bc3:87ca:7eb3:1445 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:b3e8:3e97:b9ea:4f4c maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:3139:1040:65d2:f055 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:1c69:9c53:0801:c089 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:43ca:4c70:b3af:0713 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:c164:d4da:d822:b5c0 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:33ab:784a:d947:6fe1 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:370c:1719:6265:3137 maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:c9c3:b7f6:fcc3:304e maybe
      udp_outgoing_address 2a01:4f8:2200:30ac:5c1b:cfd5:7c0e:f2e5
    '';
    proxyAddress = "10.0.5.1";
  };

  system.stateVersion = "23.05";
}

