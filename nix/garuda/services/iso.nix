{ lib, pkgs, config, garuda-lib, ... }:
with lib;
let cfg = config.services.garuda-iso;
in {
  options.services.garuda-iso = {
    enable = mkEnableOption "Garuda ISO builder";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers = {
      garuda-iso-autobuild = {
        image = "registry.gitlab.com/garuda-linux/tools/buildiso-docker/master";
        extraOptions = [ "--privileged" "--pull=always" ];
        volumes = [
          "/var/garuda/buildiso/cache/buildiso:/var/cache/garuda-tools/garuda-chroots/buildiso"
          "/var/garuda/buildiso/cache/anacron:/var/spool/anacron"
          "/var/cache/pacman/pkg/:/var/cache/pacman/pkg/"
          "/var/garuda/buildiso/iso:/var/cache/garuda-tools/garuda-builds/iso/"
          "/var/garuda/buildiso/logs:/var/cache/garuda-tools/garuda-logs/"
        ];
        cmd = [ "auto" ];
      };
    };
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    services.nginx.enable = true;
    services.nginx.virtualHosts."iso.builds.garudalinux.org" = {
      root = "/var/garuda/buildiso/iso";
      extraConfig = ''
        autoindex on;
        autoindex_format xml;
        xslt_string_param path $uri;
        xslt_string_param hostname "Garuda Linux ISO Builds";
      '';
      locations."/".extraConfig = ''
        xslt_stylesheet "${garuda-lib.xslt_style}";
      '';
    };
    networking.firewall.allowedTCPPorts = [ 80 443 ];
  };
}
