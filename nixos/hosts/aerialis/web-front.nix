{
  garuda-lib,
  pkgs,
  sources,
  ...
}:
let
  inherit (garuda-lib) allowOnlyCloudflareZerotrust;
  inherit (garuda-lib) mkCatchAllVhost;
  inherit (garuda-lib) mkCloudflaredVhost;
  inherit (garuda-lib) mkProxyVhost;
  inherit (garuda-lib) mkZerotrustVhost;

  website = pkgs.garuda-website;
  startpage = pkgs.garuda-startpage;

  vhosts = {
    "garudalinux.org" = {
      addSSL = true;
      http3 = true;
      locations = {
        "/" = {
          index = "index.html";
          root = website;
          extraConfig = ''
            # First attempt to serve request as file, then
            # as directory, then redirect to index.html (Angular) if no file found.
            try_files $uri $uri/ /index.html;
            expires 5m;
          '';
        };
        "/discord" = {
          extraConfig = "expires 12h;";
          return = "307 https://discord.gg/w5jbhq3juh";
        };
        "/telegram" = {
          extraConfig = "expires 12h;";
          return = "307 https://t.me/+TAZWHgryP6elOyS8";
        };
        "/os/" = {
          extraConfig = ''
            try_files $uri =404;
            expires 5m;

            location = /os/garuda-update/remote-update {
              expires 12h;
              return 301 https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-common-settings/-/snippets/2147440/raw/main/remote-update;
            }
            location = /os/garuda-diag/diagnostic {
              expires 12h;
              return 301 https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-common-settings/-/snippets/4892890/raw/main/diagnostics;
            }
            location = /os/garuda-update/hotfix {
              expires 5m;
              return 307 https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-common-settings/-/snippets/4899885/raw/main/hotfix;
            }
            location = /os/garuda-update/hotfix-check {
              expires 5m;
              return 200 '7';
            }
            location = /os/garuda-update/garuda-hotfixes-version {
              expires 12h;
              return 410 'Feature removed in Garuda System Maintenance 3.1.0';
            }
          '';
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
    "start.garudalinux.org" = {
      addSSL = true;
      http3 = true;
      locations = {
        "/" = {
          index = "index.html";
          root = startpage;
          extraConfig = ''
            # First attempt to serve request as file, then
            # as directory, then redirect to index.html (Angular) if no file found.
            try_files $uri $uri/ /index.html;
            expires 5m;
          '';
        };
      };
      quic = true;
      useACMEHost = "garudalinux.org";
    };
    "cloud-aio.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.60:11000";
      locationExtraConfig = ''
        client_body_buffer_size 512k;
        proxy_read_timeout 86400s;
        client_max_body_size 0;

        # Allow accessing through trusted domain
        set_real_ip_from      172.0.0.0/16;
      '';
    };
    "cloud-temp.garudalinux.org" = mkZerotrustVhost {
      upstream = "https://10.0.5.60:8080";
      locationExtraConfig = ''
        client_body_buffer_size 512k;
        proxy_read_timeout 86400s;
        client_max_body_size 0;

        # Allow accessing through trusted domain
        set_real_ip_from      172.0.0.0/16;
      '';
    };
    "search.garudalinux.org" = mkCloudflaredVhost {
      upstream = "http://10.0.5.50:5000";
    };
    "searx.garudalinux.org" = mkCloudflaredVhost {
      upstream = "http://10.0.5.50:8080";
    };
    "librey.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.50:8081";
    };
    "ffsync.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.60:5001";
    };
    "bin.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.60:8082";
    };
    "bitwarden.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.60:8081";
      serverAliases = [ "vault.garudalinux.org" ];
    };
    "forum.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.40:80";
      prologue = "client_max_body_size 100M;";
      extraLocations = {
        "/c/announcements/announcements-maintenance/45.json" = {
          proxyPass = "http://10.0.5.40:80";
          extraConfig = "expires 2m;";
        };
      };
    };
    "social.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.30";
      prologue = "client_max_body_size 100M;";
      extraLocations = {
        "/.well-known/webfinger" = {
          proxyPass = "http://10.0.5.30";
          extraConfig = ''
            if ($args ~* "resource=acct:(.*)@(chaotic.cx|social.garudalinux.org)$") {
              set $w1 $1;
              rewrite .* /.well-known/webfinger?resource=acct:$w1@garudalinux.org? break;
            }
          '';
        };
      };
    };
    "social-video.garudalinux.org" = {
      addSSL = true;
      extraConfig = ''
        client_max_body_size 100M;
        ${garuda-lib.setRealIpFromConfig}
        ${garuda-lib.nginxReverseProxySettings}
        location ~* .(mp4|webm)$ {
          proxy_pass http://10.0.5.30;
        }
      '';
      locations = {
        "/" = {
          return = "301 https://social.garudalinux.org$request_uri";
        };
      };
      http3 = true;
      quic = true;
      useACMEHost = "garudalinux.org";
    };
    "element.garudalinux.org" = {
      addSSL = true;
      extraConfig = ''
        ${garuda-lib.setRealIpFromConfig}
        ${garuda-lib.nginxReverseProxySettings}
      '';
      http3 = true;
      locations = {
        # Redirect to forum post
        "/" = {
          return = "301 https://forum.garudalinux.org/t/39538";
        };
      };
      quic = true;
      useACMEHost = "garudalinux.org";
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
      ];
      locations = {
        "/" = {
          # Redirect to forum post
          return = "301 https://forum.garudalinux.org/t/39538";
        };
      };
      quic = true;
      useACMEHost = "garudalinux.org";
    };
    "lingva.garudalinux.org" = mkCloudflaredVhost {
      upstream = "http://10.0.5.50:3002";
    };
    "reddit.garudalinux.org" = mkCloudflaredVhost {
      upstream = "http://10.0.5.50:8082";
    };
    "pgadmin.garudalinux.net" = allowOnlyCloudflareZerotrust {
      locations = {
        "/" = {
          extraConfig = ''
            ${garuda-lib.nginxReverseProxySettings}

            proxy_pass http://10.0.5.20:5050;
            proxy_set_header X-Forwarded-User $http_cf_access_authenticated_user_email;

            proxy_hide_header Cache-Control;
            proxy_hide_header Expires;
            add_header Cache-Control 'no-store';
          '';
        };
      };
    };
    "n8n-webhooks.garudalinux.net" = {
      addSSL = true;
      locations = {
        "/" = {
          return = "404";
        };
        "/webhook" = {
          extraConfig = ''
            ${garuda-lib.nginxReverseProxySettings}

            proxy_pass http://10.0.5.90:5678;
          '';
        };
      };
      useACMEHost = "garudalinux.net";
    };
    "n8n.garudalinux.net" = allowOnlyCloudflareZerotrust {
      locations = {
        "/" = {
          extraConfig = ''
            ${garuda-lib.nginxReverseProxySettings}

            proxy_pass http://10.0.5.90:5678;
          '';
        };
      };
    };
    "wiki.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.60:3001";
    };
    "backend.chaotic.cx" = {
      addSSL = true;
      http3 = true;
      locations = {
        "~ ^/(sse|metrics/live/traffic|logs/[^/]+/[^/]+|api/manager/logs|gitlab/(aur-scan|pipelines)/)" = {
          proxyPass = "http://10.0.5.70:3000";
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_http_version      1.1;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        X-Forwarded-Host $host;
            proxy_set_header        X-Forwarded-Server $host;
            proxy_set_header        Connection "";
            proxy_set_header        Upgrade $http_upgrade;

            proxy_redirect          off;
            proxy_connect_timeout   60s;
            proxy_read_timeout      3600s;
            proxy_send_timeout      3600s;
          '';
        };
        "/" = {
          proxyPass = "http://10.0.5.70:3000";
          recommendedProxySettings = false;
          extraConfig = ''
            proxy_http_version      1.1;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto $scheme;
            proxy_set_header        X-Forwarded-Host $host;
            proxy_set_header        X-Forwarded-Server $host;
            proxy_set_header        Upgrade $http_upgrade;
            proxy_set_header        Connection $connection_upgrade;

            proxy_redirect          off;
            proxy_buffering         off;
            proxy_connect_timeout   60s;
            proxy_read_timeout      60s;
            proxy_send_timeout      60s;
          '';
        };
      };
      quic = true;
      useACMEHost = "backend.chaotic.cx";
    };
    "mail.garudalinux.net" = mkProxyVhost {
      upstream = "http://10.0.5.80:80";
      acmeHost = "garudalinux.net";
      realIp = false;
    };
    "grafana.garudalinux.net" = mkCloudflaredVhost {
      upstream = "http://10.0.5.100:3010";
      acmeHost = "garudalinux.net";
      extraLocations = {
        "= /static/fly-regions.geojson" = {
          alias = ../../services/monitoring/static/fly-regions.geojson;
        };
      };
    };
    "prometheus.garudalinux.net" = mkZerotrustVhost {
      upstream = "http://10.0.5.100:9090";
      acmeHost = "garudalinux.net";
    };
    "alertmanager.garudalinux.net" = mkZerotrustVhost {
      upstream = "http://10.0.5.100:9093";
      acmeHost = "garudalinux.net";
    };
    "_" = mkCatchAllVhost { };
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  inherit
    (garuda-lib.mkWebFront {
      host = "aerialis";
      inherit vhosts;
    })
    garuda
    networking
    services
    sops
    systemd
    ;

  system.stateVersion = "25.05";
}
