{ garuda-lib
, lib
, pkgs
, sources
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
  # This is technically unecessary, but safety!
  # This refers to the Cloudflare service "Cloudflare Access" to allow only specified users to access the service
  allowOnlyCloudflareZerotrust = base_config:
    let
      config = allowOnlyCloudflared base_config;
    in
    config // {
      extraConfig = config.extraConfig + ''
        ssl_verify_client on;
        underscores_in_headers off;
        ssl_client_certificate ${sources.cloudflare-authenticated_origin_pull_ca};
      '';
      locations = lib.mapAttrs
        (_: location: location // {
          extraConfig = ''
            if ($http_cf_access_authenticated_user_email = "") {
                return 403;
            }
          '' + (location.extraConfig or "");
        })
        config.locations;
    };
  generateCloudflaredIngress = virtualHosts:
    let
      destination = "http://127.0.0.1:80";
      toIngress = array: map (host: { name = host; value = destination; }) array;
      isCloudflared = values: values ? listen && values.listen == (allowOnlyCloudflared { }).listen;
    in
    builtins.listToAttrs (lib.flatten (lib.mapAttrsToList (host: values: lib.optionals (isCloudflared values) (toIngress ([ host ] ++ (values.serverAliases or [ ])))) virtualHosts));

  website =
    let
      # Run Nx command with fake TTY to avoid panic
      # https://github.com/nrwl/nx/issues/22445
      nx = pkgs.writeScript "nx-wrapper" ''
        exec ${pkgs.faketty}/bin/faketty nx "$@"
      '';
    in
    pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "garuda-website";
      version = "1.0.0";

      src = sources.garuda-website;

      nativeBuildInputs = with pkgs; [
        nodejs_22
        pnpm_10.configHook
      ];
      pnpmDeps = pkgs.pnpm_10.fetchDeps {
        inherit (finalAttrs) pname version src;
        hash = "sha256-MpoGl7hzLAqGrqAz0hZYfQmvEZAe+V8o8jOotwlMXKI=";
      };
      buildPhase = ''
        export PATH=$(pnpm bin):$PATH
        ${nx} build && ${nx} transloco:optimize
      '';
      installPhase = ''
        cp -r ./dist/website/browser $out
      '';
    });
in
rec {
  imports = sources.defaultModules ++ [ ../modules ];

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    upstreams = {
      "grafana" = {
        servers = {
          "10.0.5.140:3001" = { };
        };
      };
      "prometheus" = {
        servers = {
          "10.0.5.140:9090" = { };
        };
      };
    };
    virtualHosts = {
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
            proxyPass = "http://10.0.5.140:80";
          };
          "/logs/" = {
            proxyPass = "http://10.0.5.140:80";
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
          # Redirect to forum post
          "/" = { return = "301 https://forum.garudalinux.org/t/39538"; };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "grafana.garudalinux.net" = allowOnlyCloudflareZerotrust {
        locations = {
          "/" = {
            proxyPass = "http://grafana";
            # Workaround the tedious origin not allowed error. This can likely be fixed
            # better, but this works for now. It is behind CF Zero Trust anyways.
            extraConfig = ''
              proxy_set_header Host grafana.garudalinux.net;
              proxy_set_header Origin https://grafana.garudalinux.net;
            '';
          };
          "/api/live/" = {
            proxyPass = "http://grafana";
            proxyWebsockets = true;
            extraConfig = ''
              proxy_set_header Host grafana.garudalinux.net;
              proxy_set_header Origin https://grafana.garudalinux.net;
            '';
          };
        };
      };
      "prometheus.garudalinux.net" = allowOnlyCloudflareZerotrust {
        locations = {
          "/" = {
            proxyPass = "http://prometheus";
          };
        };
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
      "reddit.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.110:8082";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
      };
      "pgadmin.garudalinux.net" = allowOnlyCloudflareZerotrust {
        locations = {
          "/" = {
            extraConfig = ''
              ${garuda-lib.nginxReverseProxySettings}

              proxy_pass http://10.0.5.50:5050;
              proxy_set_header X-Forwarded-User $http_cf_access_authenticated_user_email;

              proxy_hide_header Cache-Control;
              proxy_hide_header Expires;
              add_header Cache-Control 'no-store';
            '';
          };
        };
      };
      "syncthing-build.garudalinux.net" = allowOnlyCloudflareZerotrust {
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
        locations = {
          "/" = {
            extraConfig = ''
              proxy_pass http://10.0.5.140:8384;
              proxy_set_header Authorization "Basic ${garuda-lib.secrets.syncthing.esxi-build.credentials.base64}";
            '';
          };
        };
      };
      # Default catch-all for unknown domains
      "_" = {
        addSSL = true;
        extraConfig = ''
          log_not_found off;
          return 404;
        '';
        http3 = true;
        quic = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };

  services.garuda-cloudflared = {
    enable = true;
    ingress = {
      # "example.garudalinux.net" = "http://10.0.5.100:8085";
    } // (generateCloudflaredIngress services.nginx.virtualHosts);
    tunnel-credentials =
      garuda-lib.secrets.cloudflare.cloudflared.esxi-web.cred;
  };

  system.stateVersion = "23.05";
}
