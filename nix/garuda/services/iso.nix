{ lib, pkgs, config, garuda-lib, ... }:
with lib;
let
  cfg = config.services.garuda-iso;
  dockerfile = builtins.fetchTarball "https://gitlab.com/garuda-linux/tools/buildiso-docker/-/archive/master/buildiso-docker-master.tar.gz";
in {
  options.services.garuda-iso = {
    enable = mkEnableOption "Garuda ISO builder";
  };

  config = mkIf cfg.enable {
    systemd.services.buildiso = {
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      description = "Garuda-tools buildiso docker service";
      path = [ pkgs.docker ];
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "execstart" ''
          set -e
          docker run --rm --privileged --name buildiso \
            -v "/var/garuda/buildiso/cache/buildiso:/var/cache/garuda-tools/garuda-chroots/buildiso" \
            -v "/var/garuda/buildiso/cache/anacron:/var/spool/anacron" \
            -v "/var/cache/pacman/pkg/:/var/cache/pacman/pkg/" \
            -v "/var/garuda/buildiso/iso:/var/cache/garuda-tools/garuda-builds/iso/" \
            -v "/var/garuda/buildiso/logs:/var/cache/garuda-tools/garuda-logs/" \
            "''$(docker build -q "${dockerfile}")" auto
        '';
        Restart = "on-failure";
        RestartSec = "30";
      };
    };
    virtualisation.docker.enable = true;

    services.nginx.enable = true;
    services.nginx.virtualHosts."iso.builds.garudalinux.org" = {
      extraConfig = ''
        autoindex on;
        autoindex_format xml;
        xslt_string_param path $uri;
        xslt_string_param hostname "Garuda Linux ISO Builds";
      '';
      locations."/iso" = {
        root = "/var/garuda/buildiso";
        extraConfig = ''
          xslt_stylesheet "${garuda-lib.xslt_style}";
          if ($symlink_target_rel != "") {
            rewrite ^ /iso/$symlink_target_rel redirect;
          }
          if ($arg_fosshost) {
            rewrite ^/iso/(.*)$ https://mirrors.fossho.st/garuda/iso/$1? permanent;
          }
          if ($arg_sourceforge) {
            rewrite ^/iso/(.*)$ https://sourceforge.net/projects/garuda-linux/files/$1? permanent;
          }
          break;
        '';
      };
      locations."/".extraConfig = "return 301 https://builds.garudalinux.org$request_uri;";
      useACMEHost = "garudalinux.org";
      forceSSL = true;
    };

    services.rsyncd.enable = true;
    services.rsyncd.settings = {
      iso = {
        path = "/var/garuda/buildiso/iso/";
        comment = "ISO downloads";
        "read only" = "yes";
      };
      global = {
        gid = "nobody";
        "max connections" = 80;
        uid = "nobody";
        "use chroot" = false;
        "max verbosity" = 3;
        "transfer logging" = true;
      };
    };

    networking.firewall.allowedTCPPorts = [ 80 443 config.services.rsyncd.port ];
  };
}
