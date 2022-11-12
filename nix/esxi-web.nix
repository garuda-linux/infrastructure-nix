{ garuda-lib, lib, sources, pkgs, ... }:

let
  setRealIpFromConfig = lib.concatMapStrings (ip: ''
    set_real_ip_from ${ip};
  '')
    (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4));
in {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-web";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.20";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Configure backups to backup-dragon
  services.borgbackup.jobs = {
    backupToBackupDragon = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-web -p 666";
      };
      paths = [ "/var/garuda/docker-compose-runner/esxi-web" ];
      prune.keep = {
        within = "1d";
        daily = 7;
        weekly = 2;
        monthly = 1;
      };
      repo = "borg@89.58.13.188:.";
      startAt = "daily";
    };
  };

  # Enable our docker-compose stack
  services.docker-compose-runner.esxi-web = {
    source = ./docker-compose/esxi-web;
    envfile = garuda-lib.secrets.docker-compose.esxi-web;
  };

  # MongoDB port is being forwarded to this VM
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  # Cloudflared access to Meshcentral webinterface
  services.cloudflared = {
    enable = true;
    ingress = {
      "mesh.garudalinux.net" = "http://127.0.0.1:80";
      "matrixadmin.garudalinux.net" = "http://esxi-web-two.local:8081";
    };
    tunnel-id = garuda-lib.secrets.cloudflared.esxi-web.id;
    tunnel-credentials = garuda-lib.secrets.cloudflared.esxi-web.cred;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            index = "index.html";
            root = sources.garuda-website;
          };
          "/discord" = {
            extraConfig = "expires 12h;";
            return = "307 https://discord.gg/w5jbhq3juh";
          };
          "/telegram" = {
            extraConfig = "expires 12h;";
            return = "307 https://t.me/garudalinux";
          };
          "/os/garuda-update/backuprepo" = {
            extraConfig = ''
              rewrite ^/os/garuda-update/backuprepo/(.*)$ https://geo-mirror.chaotic.cx/chaotic-aur/$1 redirect;
            '';
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "cloud.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            extraConfig = ''
              # Increase our buffer size to allow bigger up- & downloads
              proxy_max_temp_file_size              2048M;
              proxy_request_buffering               off;

              # HSTS headers
              add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload" always;

              # Allow accessing through trusted domain
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              set_real_ip_from      172.0.0.0/16;
            '';
            proxyPass = "https://192.168.1.40:443";
          };
          "/.well-known/carddav" = {
            extraConfig = "expires 12h;";
            return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/caldav" = {
            extraConfig = "expires 12h;";
            return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/webfinger" = {
            return = "301 $scheme://$host/index.php/.well-known/webfinger";
            extraConfig = ''
              access_log    off;
              log_not_found off;
            '';
          };
          "/.well-known/nodeinfo" = {
            extraConfig = ''
              access_log    off;
              log_not_found off;
            '';
            return = "301 $scheme://$host/index.php/.well-known/nodeinfo";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.net" = {
        locations = {
          "/" = {
            extraConfig = ''
              proxy_send_timeout 330s;
              proxy_read_timeout 330s;
              proxy_set_header Connection $http_connection;
              proxy_set_header Upgrade $http_upgrade;

              allow 127.0.0.1;
              deny all;

              set $delimeter "";
              if ($is_args) {
                set $delimeter "&";
              }
              set $args "$args''${delimeter}user=cfaccess&pass=${garuda-lib.secrets.meshcentral.cfaccess-user}";
              proxy_pass http://esxi-web-two.local:22260;
            '';
          };
        };
      };
      "search.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:5000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "searx.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:8080"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:5001"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "repo.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://192.168.1.30:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "start.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://127.0.0.1:8084"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "irc.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://127.0.0.1:9000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bin.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:8083"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bitwarden.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8082";
            proxyWebsockets = true;
          };
        };
        http3 = true;
        serverAliases = [ "vault.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "status.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { tryFiles = "/status.html /status.html"; };
          "=/status.html" = {
            extraConfig = "expires 30d;";
            root = "${sources.garuda-website}/internal";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "stats.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { tryFiles = "/stats.html /stats.html"; };
          "=/stats.html" = {
            extraConfig = "expires 30d;";
            root = "${sources.garuda-website}/internal";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "forum.garudalinux.org" = {
        addSSL = true;
        extraConfig = "client_max_body_size 100M;";
        locations = { "/" = { proxyPass = "http://192.168.1.70:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "social.garudalinux.org" = {
        addSSL = true;
        extraConfig = "client_max_body_size 100M;";
        locations = {
          "/" = {
            proxyPass = "https://192.168.1.50:443";
            proxyWebsockets = true;
            extraConfig = ''
              ${setRealIpFromConfig}
              real_ip_header CF-Connecting-IP;
              proxy_set_header Host social.garudalinux.org;
              proxy_set_header X-Forwarded-For $remote_addr;
            '';
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "iso.builds.garudalinux.org" = {
        addSSL = true;
        extraConfig = "proxy_buffering off;";
        locations = { "/" = { proxyPass = "http://192.168.1.60:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "element.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { proxyPass = "http://esxi-web-two.local:8080"; };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "wiki.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { proxyPass = "http://esxi-web-two.local:3001"; };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            proxyPass = "http://esxi-web-two.local:22260";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_read_timeout 330s;
              proxy_send_timeout 330s;
              proxy_set_header Connection $http_connection;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_set_header X-Forwarded-Host $host:$server_port;
              proxy_set_header X-Forwarded-Proto $scheme;
            '';
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "matrix.garudalinux.org" = {
        listen = [
          {
            addr = "0.0.0.0";
            port = 443;
            ssl = true;
          }
          {
            addr = "0.0.0.0";
            port = 8448;
            ssl = true;
          }
        ];
        locations = {
          "/" = {
            extraConfig = "client_max_body_size 50M;";
            proxyPass = "http://esxi-web-two.local:8008";
          };
        };
        http3 = true;
        addSSL = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };

  services.netdata.configDir = {
    "go.d/web_log.conf" = pkgs.writeText "web_log.conf" ''
      - name: main
        path: /var/log/nginx/*
    '';
  };

  system.stateVersion = "22.05";
}
