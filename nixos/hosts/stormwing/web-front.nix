{
  config,
  garuda-lib,
  lib,
  sources,
  ...
}:
let
  inherit (garuda-lib) allowOnlyCloudflareZerotrust;
  inherit (garuda-lib) mkCatchAllVhost;
  inherit (garuda-lib) mkProxyVhost;

  webFront = garuda-lib.mkWebFront {
    host = "stormwing";
    inherit vhosts;
  };

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
            include ${config.sops.templates."syncthing-build-auth.conf".path};
          '';
        };
      };
    };
    "_" = mkCatchAllVhost { };
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  inherit (webFront)
    garuda
    networking
    services
    systemd
    ;

  sops = lib.recursiveUpdate webFront.sops {
    secrets."syncthing/gui_basic_auth" = { };
    templates."syncthing-build-auth.conf" = {
      owner = "nginx";
      content = ''
        proxy_set_header Authorization "Basic ${config.sops.placeholder."syncthing/gui_basic_auth"}";
      '';
      restartUnits = [ "nginx.service" ];
    };
  };

  system.stateVersion = "25.05";
}
