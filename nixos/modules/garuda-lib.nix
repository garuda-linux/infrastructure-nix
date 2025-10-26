{
  config,
  lib,
  sources,
  pkgs,
  ...
}:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ../../secrets/buildtime.json);
  nginxReverseProxySettingsPkg = pkgs.writeText "garuda-proxy-settings.conf" ''
    proxy_redirect          off;
    proxy_connect_timeout   60s;
    proxy_send_timeout      60s;
    proxy_read_timeout      60s;
    proxy_http_version      1.1;
    proxy_set_header        Upgrade $http_upgrade;
    proxy_set_header        Connection $connection_upgrade;
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $remote_addr;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $host;
  '';
  nginxReverseProxySettings = ''
    include ${nginxReverseProxySettingsPkg};
  '';
  setRealIpFromConfigPkg = pkgs.writeText "garuda-cf-real-ip.conf" (
    lib.concatMapStrings (ip: ''
      set_real_ip_from ${ip};
    '') (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4))
    + "\nreal_ip_header CF-Connecting-IP;"
  );
  setRealIpFromConfig = ''
    include ${setRealIpFromConfigPkg};
  '';
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
        extraConfig = (config.extraConfig or "") + ''
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
      extraConfig = config.extraConfig + ''
        ssl_verify_client on;
        underscores_in_headers off;
        ssl_client_certificate ${sources.cloudflare-authenticated_origin_pull_ca};
      '';
      locations = lib.mapAttrs (
        _: location:
        location
        // {
          extraConfig = ''
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
{
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { };
  };
  config = {
    _module.args.garuda-lib = config.garuda-lib;
    # Defaults
    garuda-lib = {
      behind_proxy = false;
      inherit
        setRealIpFromConfig
        nginxReverseProxySettings
        allowOnlyCloudflared
        allowOnlyCloudflareZerotrust
        generateCloudflaredIngress
        ;
      minimalContainer = false;
      chaoticUsers = false;
      unifiedUID = false;
      sshkeys = {
        ed25519 = "/etc/ssh/ssh_host_ed25519_key";
        rsa = "/etc/ssh/ssh_host_rsa_key";
      };
      inherit secrets;
      xslt_style = ./static/style.xslt;
      dns = {
        stormwing = "157.180.57.51";
        aerialis = "157.180.57.100";
      };
    };
  };
}
