{ garuda-lib
, sources
, lib
, ...
}:
let
  allowOnlyCloudflared = config: (
    config // {
      listen = [
        {
          addr = "127.0.0.1";
          port = 80;
        }
      ];
      extraConfig = (config.extraConfig or "") + ''
        real_ip_header CF-Connecting-IP;
        set_real_ip_from 127.0.0.1;
      '';
    }
  );
  generateCloudflaredIngress = virtualHosts:
    let
      destination = "http://127.0.0.1:80";
      toIngress = array: map (host: { name = host; value = destination; }) array;
      isCloudflared = values: values ? listen && values.listen == (allowOnlyCloudflared { }).listen;
    in
    builtins.listToAttrs (lib.flatten (lib.mapAttrsToList (host: values: lib.optionals (isCloudflared values) (toIngress ([ host ] ++ (values.serverAliases or [ ])))) virtualHosts));
in
rec {
  imports = sources.defaultModules ++ [ ../modules ];

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "cloud.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
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
      "cloud-aio.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = ''
              client_body_buffer_size 512k;
              proxy_read_timeout 86400s;
              client_max_body_size 0;

              # Allow accessing through trusted domain
              set_real_ip_from      172.0.0.0/16;
            '';
            proxyPass = "http://10.0.5.100:11000";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "cloud-temp.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = ''
              client_body_buffer_size 512k;
              proxy_read_timeout 86400s;
              client_max_body_size 0;

                 # Allow accessing through trusted domain
                 set_real_ip_from      172.0.0.0/16;
            '';
            proxyPass = "https://10.0.5.100:8080";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "search.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.110:5000"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
      };
      "searx.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.110:8080"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
      };
      "librey.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.110:8081"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = { "/" = { proxyPass = "http://10.0.5.100:5001"; }; };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "start.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.100:8081";
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
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "https://10.0.5.80:443";
          };
          "/.well-known/webfinger" = {
            proxyPass = "https://10.0.5.80:443";
            extraConfig = ''
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
          ${garuda-lib.nginxReverseProxySettings}
          location ~* .(mp4|webm)$ {
            proxy_pass https://10.0.5.80:443;
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
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.20:80";
          };
          "/logs/" = {
            proxyPass = "http://10.0.5.140:8080/";
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 330s;
            '';
          };
        };
        quic = true;
        serverAliases = [ "cf-builds.garudalinux.org" "iso.builds.garudalinux.org" ];
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
          "/" = { proxyPass = "http://10.0.5.100:8084"; };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "wiki.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
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
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:22260";
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_read_timeout 330s;
              proxy_send_timeout 330s;
            '';
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "mesh.garudalinux.net" = allowOnlyCloudflared {
        locations = {
          "/" = {
            extraConfig = ''
              proxy_http_version 1.1;
              proxy_send_timeout 330s;
              proxy_read_timeout 330s;

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
      "piped.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        extraConfig = ''
          location / {
            ${garuda-lib.nginxReverseProxySettings}
            proxy_pass http://10.0.5.110:8088;
          }
        '';
        http3 = true;
        quic = true;
        serverAliases = [ "piped-api.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      # piped-proxy without cloudflare, this is where the actual video is hosted
      "piped-proxy.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            ${garuda-lib.setRealIpFromConfig}
            ${garuda-lib.nginxReverseProxySettings}
            proxy_buffering off;
            proxy_pass http://10.0.5.110:8088;
          }
        '';
        http3 = true;
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "lemmy.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
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
      "lingva.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.110:3002";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
      };
      "websurfx.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          ${garuda-lib.nginxReverseProxySettings}
        '';
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.100:8086";
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
      "matrixadmin.garudalinux.net" = "http://10.0.5.100:8085";
    } // (generateCloudflaredIngress services.nginx.virtualHosts);
    tunnel-credentials =
      garuda-lib.secrets.cloudflare.cloudflared.esxi-web.cred;
  };

  system.stateVersion = "23.05";
}
