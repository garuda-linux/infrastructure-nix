{ garuda-lib, lib, sources, ... }: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  networking.hostName = "web-front";

  # Enable our docker-compose stack
  services.docker-compose-runner.web-dragon = {
    envfile = garuda-lib.secrets.docker-compose.web-dragon;
    source = ./docker-compose/web-dragon;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
          "/os/garuda-update/remote-update" = {
            extraConfig = "expires 12h;";
            return =
              "301 https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-common-settings/-/snippets/2147440/raw/main/remote-update";
          };
          "/os/garuda-update/garuda-hotfixes-version" = {
            extraConfig = "expires 5m;";
            return = "200 '1'";
          };
          "/.well-known/webfinger" = {
            extraConfig = "expires 12h;";
            return = "301 https://social.garudalinux.org$request_uri";
          };
        };
        http3 = true;
        serverAliases = [ "www.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "cloud.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = {
          "/" = {
            extraConfig = ''
              # Increase our buffer size to allow bigger up- & downloads
              client_max_body_size                  2048M;
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
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
              proxy_pass http://esxi-web-two:22260;
            '';
          };
        };
      };
      "search.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = { "/" = { proxyPass = "http://127.0.0.1:5000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "searx.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = { "/" = { proxyPass = "http://127.0.0.1:8080"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = { "/" = { proxyPass = "http://127.0.0.1:8083"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bitwarden.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
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
        extraConfig = ''
          client_max_body_size 100M;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
          proxy_set_header X-Forwarded-For $remote_addr;
        '';
        locations = {
          "/" = { proxyPass = "http://192.168.1.70:80"; };
          "/c/announcements/announcements-maintenance/45.json" = {
            extraConfig = "expires 2m;";
            proxyPass = "http://192.168.1.70:80";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "social.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          client_max_body_size 100M;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = {
          "/" = {
            proxyPass = "https://192.168.1.50:443";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host social.garudalinux.org;
            '';
          };
          "/.well-known/webfinger" = {
            proxyPass = "https://192.168.1.50:443";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host social.garudalinux.org;
              if ($args ~* "resource=acct:(.*)@(chaotic.cx|social.garudalinux.org)$") {
                set $w1 $1;
                rewrite .* /.well-known/webfinger?resource=acct:$w1@garudalinux.org? break;
              }
            '';
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "social-video.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          client_max_body_size 100M;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
          location ~* .(mp4|webm)$ {
            proxy_pass https://192.168.1.50:443;
            proxy_set_header Host social.garudalinux.org;
          }
        '';
        locations = {
          "/" = { return = "301 https://social.garudalinux.org$request_uri"; };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "builds.garudalinux.org" = {
        addSSL = true;
        serverAliases =
          [ "iso.builds.garudalinux.org" "cf-builds.garudalinux.org" ];
        extraConfig = ''
          proxy_buffering off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
          proxy_set_header Host $host;
        '';
        locations = { "/" = { proxyPass = "http://192.168.1.60:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "element.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = {
          "/" = { proxyPass = "http://esxi-web-two:8080"; };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "wiki.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = {
          "/" = { proxyPass = "http://esxi-web-two:3001"; };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = {
          "/" = {
            proxyPass = "http://esxi-web-two:22260";
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
            proxyPass = "http://esxi-web-two:8008";
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

  system.stateVersion = "23.05";
}
