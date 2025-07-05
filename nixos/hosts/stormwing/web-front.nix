{
  config,
  garuda-lib,
  lib,
  sources,
  ...
}:
let
  allowOnlyCloudflared =
    config:
    (
      config
      // {
        listen = [
          {
            addr = "127.0.0.1";
            port = 80;
          }
        ];
        extraConfig =
          (config.extraConfig or "")
          + ''
            real_ip_header CF-Connecting-IP;
            set_real_ip_from 127.0.0.1;
          '';
      }
    );
  # This is technically unecessary, but safety!
  # This refers to the Cloudflare service "Cloudflare Access" to allow only specified users to access the service
  allowOnlyCloudflareZerotrust =
    base_config:
    let
      config = allowOnlyCloudflared base_config;
    in
    config
    // {
      extraConfig =
        config.extraConfig
        + ''
          ssl_verify_client on;
          underscores_in_headers off;
          ssl_client_certificate ${sources.cloudflare-authenticated_origin_pull_ca};
        '';
      locations = lib.mapAttrs (
        _: location:
        location
        // {
          extraConfig =
            ''
              if ($http_cf_access_authenticated_user_email = "") {
                  return 403;
              }
            ''
            + (location.extraConfig or "");
        }
      ) config.locations;
    };
  generateCloudflaredIngress =
    virtualHosts:
    let
      destination = "http://127.0.0.1:80";
      toIngress =
        array:
        map (host: {
          name = host;
          value = destination;
        }) array;
      isCloudflared = values: values ? listen && values.listen == (allowOnlyCloudflared { }).listen;
    in
    builtins.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          host: values:
          lib.optionals (isCloudflared values) (toIngress ([ host ] ++ (values.serverAliases or [ ])))
        ) virtualHosts
      )
    );
in
rec {
  imports = sources.defaultModules ++ [ ../../modules ];

  services.nginx = {
    enable = true;
    virtualHosts = {
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
            proxyPass = "http://10.0.5.30:80";
          };
          "/logs/" = {
            proxyPass = "http://10.0.5.30:80";
            extraConfig = ''
              proxy_buffering off;
              proxy_read_timeout 330s;
            '';
          };
        };
        quic = true;
        serverAliases = [
          "cf-builds.garudalinux.org"
          "iso.builds.garudalinux.org"
        ];
        useACMEHost = "garudalinux.org";
      };
      "syncthing-build.garudalinux.net" = allowOnlyCloudflareZerotrust {
        extraConfig = ''
          ${garuda-lib.nginxReverseProxySettings}
        '';
        locations = {
          "/" = {
            extraConfig = ''
              proxy_pass http://10.0.5.30:8384;
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
    tunnel-credentials = config.sops.secrets."cloudflare/tunnels/stormwing".path;
  };

  sops.secrets."cloudflare/tunnels/stormwing" = { };

  system.stateVersion = "25.05";
}
