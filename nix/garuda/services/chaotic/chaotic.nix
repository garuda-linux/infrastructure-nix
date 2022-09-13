{ lib, pkgs, config, garuda-lib, sources, ... }:
with lib;
let
  cfg = config.services.chaotic;
  toolbox = pkgs.stdenv.mkDerivation {
    src = sources.chaotic-toolbox;
    name = "chaotic-toolbox";
    installFlags = "PREFIX=${placeholder "out"}";
    buildFlags = "PREFIX=${placeholder "out"}";
    patches = [ ./patch.diff ];
    postFixup = ''
      "${pkgs.rsync}/bin/rsync" -a "${sources.chaotic-toolbox}/guest/" "$out/lib/chaotic/guest/"
    '';
  };
  repoctl = pkgs.buildGoModule {
    src = sources.repoctl;
    vendorSha256 = null;
    name = "repoctl";
    doCheck = false;
  };
  repodir = "${cfg.repos-dir}/${cfg.db-name}";
in {
  options.services.chaotic = {
    enable = mkEnableOption "Chaotic AUR";
    db-name = mkOption {
      type = types.str;
      default = "chaotic-aur";
    };
    cluster-name = mkOption {
      type = types.str;
    };
    repos-dir = mkOption {
      type = types.str;
      default = "/srv/http/repos/";
      description = "Where repos will be stored as well as the nginx webroot served.";
    };
    host = mkOption {
      type = types.str;
      example = "repo.garudalinux.org";
      description = "The hostname under which the repo will be served.";
    };
    extraConfig = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = mkIf cfg.enable {
    users.groups = {
      "chaotic_op" = { };
    };
    environment.systemPackages = [ toolbox pkgs.unstable.arch-install-scripts pkgs.git pkgs.unstable.pacman repoctl pkgs.screen pkgs.gnupg ];
    environment.etc = {
      "pacman.conf".text = ''
[options]
Architecture = x86_64
SigLevel = Never
[garuda]
Include = /etc/pacman.d/chaotic-mirrorlist
[core]
Include = /etc/pacman.d/mirrorlist
[extra]
Include = /etc/pacman.d/mirrorlist
[community]
Include = /etc/pacman.d/mirrorlist
[multilib]
Include = /etc/pacman.d/mirrorlist
[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
      '';
    "pacman.d/mirrorlist".text = ''
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = https://cloudflaremirrors.com/archlinux/$repo/os/$arch
    '';
    "pacman.d/chaotic-mirrorlist".text = ''
# Automatic per-country routing of the mirrors below.
Server = https://geo-mirror.chaotic.cx/$repo/$arch

# CDN (delayed syncing)
# By: Fosshost
Server = https://cdn-mirror.chaotic.cx/$repo/$arch
    '';
    "chaotic.conf".text = ''
export CAUR_DB_NAME=${cfg.db-name}
export CAUR_DEPLOY_PKGS=${repodir}/x86_64
export CAUR_DEPLOY_LOGS=${repodir}/logs
export CAUR_DEPLOY_LOGS_FILTERED=$CAUR_DEPLOY_LOGS/filtered
export CAUR_DEPLOY_LAST=${repodir}/lastupdate

export CAUR_URL=http://${cfg.host}/''${CAUR_DB_NAME}/x86_64
export CAUR_FILL_DEST=http://${cfg.host}/''${CAUR_DB_NAME}/pkgs.files.txt
export CAUR_CLUSTER_NAME=${cfg.cluster-name}
export CAUR_ROUTINES=/var/cache/chaotic/routines

export REPOCTL_CONFIG=/etc/xdg/repoctl/config.toml
export CAUR_GPG_PATH="${pkgs.gnupg}/bin/gpg"

${cfg.extraConfig}

renice -n 19 $$
export TERM=screen
    '';
    "xdg/repoctl/config.toml".text = ''
repo = "${repodir}/x86_64/${cfg.db-name}.db.tar.zst"
backup = true
backup_dir = "${repodir}/archive/"
interactive = false
columnate = false
color = "auto"
quiet = false
    '';
    };
    systemd.services.chaotic-setup = {
      wantedBy = [ "multi-user.target" ];
      description = "Chaotic setup";
      path = [ pkgs.git pkgs.pacman pkgs.gnupg ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "execstart" ''
          set -e
          if [ ! -d "/var/lib/chaotic" ]; then mkdir "/var/lib/chaotic"; fi
          if [ ! -d "/var/lib/chaotic/packages" ]; then git clone "https://github.com/chaotic-aur/packages" /var/lib/chaotic/packages; fi
          if [ ! -d "/var/lib/chaotic/interfere" ]; then git clone "https://github.com/chaotic-aur/interfere" /var/lib/chaotic/interfere; fi
          if [ ! -d "/etc/pacman.d/gnupg" ]; then pacman-key --init; fi
          mkdir -p "${repodir}/x86_64"
          mkdir -p "${repodir}/logs"
        '';
      };
    };
    security.wrappers = { 
      chaotic = { 
        setuid = true;
        owner = "root";
        group = "chaotic_op";
        source = "${toolbox}/bin/chaotic";
        permissions = "u+rx,g+rx,o-rx";
      };
    };
    services.nginx.enable = true;
    services.nginx.virtualHosts.${cfg.host} = {
      extraConfig = ''
        autoindex on;
      '';
      root = cfg.repos-dir;
    };
    networking.hosts = {
      "127.0.0.1" = [ cfg.host ];
    };
  };
}
