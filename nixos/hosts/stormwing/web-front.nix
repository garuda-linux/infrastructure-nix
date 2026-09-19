{
  garuda-lib,
  sources,
  ...
}:
let
  inherit (garuda-lib) allowOnlyCloudflareZerotrust;
  inherit (garuda-lib) mkCatchAllVhost;
  inherit (garuda-lib) mkProxyVhost;

  vhosts = {
    "builds.garudalinux.org" = mkProxyVhost {
      upstream = "http://10.0.5.10:80";
      prologue = "proxy_buffering off;";
      serverAliases = [
        "cf-builds.garudalinux.org"
        "iso.builds.garudalinux.org"
      ];
      extraLocations = {
        "/logs/" = {
          proxyPass = "http://10.0.5.10:80";
          extraConfig = ''
            proxy_buffering off;
            proxy_read_timeout 330s;
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
            proxy_pass http://10.0.5.10:8384;
            proxy_set_header Authorization "Basic ${garuda-lib.secrets.syncthing.esxi-build.credentials.base64}";
          '';
        };
      };
    };
    "_" = mkCatchAllVhost { };
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  inherit
    (garuda-lib.mkWebFront {
      host = "stormwing";
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
