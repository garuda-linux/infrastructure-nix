{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

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
        http3 = true;
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
        quic = true;
        serverAliases = [ "www.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "cloud.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
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
            proxyPass = "https://10.0.5.100:443";
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
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "search.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.110:5000"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "searx.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.110:8080"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:5001"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "repo.garudalinux.org" = {
        addSSL = true;
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.30:80"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "start.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:8083"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "irc.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:9000"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "bin.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:8082"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "bitwarden.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.100:8081";
            proxyWebsockets = true;
          };
        };
        quic = true;
        serverAliases = [ "vault.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "status.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = { tryFiles = "/status.html /status.html"; };
          "=/status.html" = {
            extraConfig = "expires 30d;";
            root = "${sources.garuda-website}/internal";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "stats.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = { tryFiles = "/stats.html /stats.html"; };
          "=/stats.html" = {
            extraConfig = "expires 30d;";
            root = "${sources.garuda-website}/internal";
          };
        };
        quic = true;
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
        http3 = true;
        locations = {
          "/" = { proxyPass = "http://10.0.5.70:80"; };
          "/c/announcements/announcements-maintenance/45.json" = {
            extraConfig = "expires 2m;";
            proxyPass = "http://10.0.5.70:80";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "social.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          client_max_body_size 100M;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "https://10.0.5.80:443";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host social.garudalinux.org;
            '';
          };
          "/.well-known/webfinger" = {
            proxyPass = "https://10.0.5.80:443";
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
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "social-video.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          client_max_body_size 100M;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
          location ~* .(mp4|webm)$ {
            proxy_pass https://10.0.5.80:443;
            proxy_set_header Host social.garudalinux.org;
          }
        '';
        locations = {
          "/" = { return = "301 https://social.garudalinux.org$request_uri"; };
        };
        http3 = true;
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "builds.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          proxy_buffering off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
          proxy_set_header Host $host;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.20:80"; }; };
        quic = true;
        serverAliases = [ "cf-builds.garudalinux.org" "iso.builds.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "element.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = { proxyPass = "http://10.0.5.100:8084"; };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "wiki.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:3001"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:22260";
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
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.net" = {
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        listen = [
          {
            addr = "127.0.0.1";
            port = 80;
          }
        ];
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
              proxy_pass http://10.0.5.60:22260;
            '';
          };
        };
      };
      "matrix.garudalinux.org" = {
        addSSL = true;
        http3 = true;
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
            proxyPass = "http://10.0.5.100:8008";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "piped.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            ${garuda-lib.setRealIpFromConfig}
            real_ip_header CF-Connecting-IP;
            proxy_buffering off;
            proxy_pass http://10.0.5.110:8088;
            proxy_set_header Host $host;
          }
        '';
        http3 = true;
        quic = true;
        serverAliases = [ "piped-api.garudalinux.org" "piped-proxy.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "invidious.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = ''
              proxy_buffering off;
              proxy_set_header Connection "";
              proxy_http_version 1.1;
            '';
            proxyPass = "http://10.0.5.110:3003";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "lemmy.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.120:80";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "lingva.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.110:3002";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };

  # Cloudflared access to Meshcentral webinterface
  services.garuda-cloudflared = {
    enable = true;
    ingress = {
      "mesh.garudalinux.net" = "http://127.0.0.1:80";
      "matrixadmin.garudalinux.net" = "http://10.0.5.100:8085";
    };
    tunnel-credentials =
      garuda-lib.secrets.cloudflare.cloudflared.esxi-web.cred;
  };

  system.stateVersion = "23.05";
}
