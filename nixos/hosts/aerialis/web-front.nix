{
  config,
  garuda-lib,
  pkgs,
  sources,
  ...
}:
let
  inherit (garuda-lib) allowOnlyCloudflared;
  inherit (garuda-lib) allowOnlyCloudflareZerotrust;
  inherit (garuda-lib) generateCloudflaredIngress;

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
        hash = "sha256-IatSw2EUQVSt0lXgxBCDzCfyzEHNq8JffFodIALGXTk=";
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
  imports = sources.defaultModules ++ [ ../../modules ];

  services.nginx = {
    enable = true;
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
            return = "301 https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-common-settings/-/snippets/2147440/raw/main/remote-update";
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
            proxyPass = "http://10.0.5.60:11000";
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
            proxyPass = "https://10.0.5.60:8080";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "search.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.50:5000";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
      };
      "searx.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.50:8080";
          };
        };
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
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.50:8081";
          };
        };
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
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:5001";
          };
        };
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
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:9000";
          };
        };
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
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:8082";
          };
        };
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
            proxyPass = "http://10.0.5.60:8081";
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
          "/" = {
            proxyPass = "http://10.0.5.40:80";
          };
          "/c/announcements/announcements-maintenance/45.json" = {
            extraConfig = "expires 2m;";
            proxyPass = "http://10.0.5.40:80";
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
            proxyPass = "http://10.0.5.30";
          };
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
      "lingva.garudalinux.org" = allowOnlyCloudflared {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:3002";
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
            proxyPass = "http://10.0.5.50:8082";
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

              proxy_pass http://10.0.5.20:5050;
              proxy_set_header X-Forwarded-User $http_cf_access_authenticated_user_email;

              proxy_hide_header Cache-Control;
              proxy_hide_header Expires;
              add_header Cache-Control 'no-store';
            '';
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
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.60:3001";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
      };
      "chaotic-backend.garudalinux.org" = {
        addSSL = true;
        http3 = true;
        locations = {
          "/" = {
            proxyPass = "http://10.0.5.70:3000";
          };
        };
        quic = true;
        useACMEHost = "garudalinux.org";
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
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
    tunnel-credentials = config.sops.secrets."cloudflare/tunnels/aerialis".path;
  };

  sops.secrets."cloudflare/tunnels/aerialis" = { };

  system.stateVersion = "25.05";
}
