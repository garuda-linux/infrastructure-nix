{ lib, pkgs, config, garuda-lib, ... }:
with lib;
let
  cfg = config.services.chaotic;
  toolbox_src = builtins.fetchGit {
    url = "https://github.com/chaotic-aur/toolbox";
    ref = "main";
  };
  toolbox = pkgs.stdenv.mkDerivation {
    src = toolbox_src;
    name = "chaotic-toolbox";
    installFlags = "PREFIX=${placeholder "out"}";
    buildFlags = "PREFIX=${placeholder "out"}";
    patches = [ ./patch.diff ];
    postFixup = ''
      "${pkgs.rsync}/bin/rsync" -a "${toolbox_src}/guest/" "$out/lib/chaotic/guest/"
    '';
  };
  repoctl = pkgs.buildGoModule {
    src = builtins.fetchGit {
      url = "https://github.com/cassava/repoctl";
      ref = "master";
    };
    vendorSha256 = null;
    name = "repoctl";
    doCheck = false;
  };
  unstable = import <nixos-unstable> {};
in {
  options.services.chaotic = {
    enable = mkEnableOption "Chaotic AUR";
    reponame = mkOption {
      type = types.str;
      default = "chaotic-aur";
    };
  };

  config = mkIf cfg.enable {
    users.groups = {
      "chaotic_op" = { };
    };
    environment.systemPackages = [ toolbox unstable.arch-install-scripts pkgs.git unstable.pacman repoctl ];
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
          mkdir -p "/srv/http/repos/${cfg.reponame}/x86_64"
          mkdir -p "/srv/http/repos/${cfg.reponame}/logs"
        '';
      };
    };
    security.wrappers = { 
      chaotic = { 
        setuid = true;
        owner = "root";
        group = "chaotic_op";
        source = "${toolbox}/bin/chaotic";
      };
    };
  };
}
