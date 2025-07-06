{
  config,
  garuda-lib,
  sources,
  ...
}:
let
  inherit (garuda-lib) allowOnlyCloudflareZerotrust;
  inherit (garuda-lib) generateCloudflaredIngress;
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
            proxyPass = "http://10.0.5.10:80";
          };
          "/logs/" = {
            proxyPass = "http://10.0.5.10:80";
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
              proxy_pass http://10.0.5.10:8384;
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
