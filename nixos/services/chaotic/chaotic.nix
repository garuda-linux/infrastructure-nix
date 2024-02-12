{ config
, garuda-lib
, lib
, pkgs
, inputs
, sources
, ...
}:
with lib;
let
  cfg = config.services.chaotic;
  toolbox = pkgs.stdenv.mkDerivation {
    src = sources.chaotic-toolbox;
    name = "chaotic-toolbox";
    installFlags = "PREFIX=${placeholder "out"}";
    buildFlags = "PREFIX=${placeholder "out"}";
    patches = [ ./patch.diff ] ++ cfg.patches;
    postFixup = ''
      "${pkgs.rsync}/bin/rsync" -a "${sources.chaotic-toolbox}/guest/bin/" "$out/lib/chaotic/guest/bin/"
    '';
  };
  repoctl = pkgs.buildGoModule {
    src = sources.repoctl;
    vendorHash = null;
    name = "repoctl";
    doCheck = false;
  };
  telegram-send = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "telegram-send";
    version = "0.36";

    src = pkgs.python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "sha256-6RmKVjqBmVeioQvtil8ZbDhiIW9v7WLPHTarP5/V4yk=";
    };

    doCheck = false;

    propagatedBuildInputs = with pkgs.python3.pkgs; [
      appdirs
      colorama
      python-telegram-bot
    ];
  };
  repodir = "${cfg.repos-dir}/${cfg.db-name}";
  # arch-install-scripts is broken because resholve seems to fail to build because of a broken python package (python2.7-wheel). Pull in resholve from nixpkgs-stable.
  arch-install-scripts = pkgs.arch-install-scripts.override { inherit (inputs.nixpkgs-stable.legacyPackages."${pkgs.hostPlatform.system}") resholve; };
in
{
  options.services.chaotic = {
    enable = mkEnableOption "Chaotic AUR";
    db-name = mkOption {
      type = types.str;
      default = "chaotic-aur";
    };
    cluster-name = mkOption { type = types.str; };
    repos-dir = mkOption {
      type = types.str;
      default = "/srv/http/repos/";
      description =
        "Where repos will be stored as well as the nginx webroot served.";
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
    interfere = mkOption {
      type = types.str;
      default = "https://github.com/chaotic-aur/interfere";
    };
    packages = mkOption {
      type = types.str;
      default = "https://github.com/chaotic-aur/packages";
    };
    calendarmap = mkOption {
      type = types.attrs;
      description = "A list of systemd calendar values matching routine names.";
      default = {
        "morning" = "*-*-* 6:30:00";
        "afternoon" = "*-*-* 12:30:00";
        "midnight" = "*-*-* 00:30:00";
        "nightly" = "*-*-* 19:30:00";
        "hourly" = "hourly";
        "hourly.1" = "*-*-* 01,03,05,07,09,11,13,15,17,19,21,23:00:00";
        "hourly.2" = "*-*-* 00,02,04,06,08,10,12,14,16,18,20,22:00:00";
        "tkg-wine" = "*-*-* 15:30:00";
      };
    };
    routines = mkOption {
      type = types.listOf types.str;
      default = [ ];
    };
    patches = mkOption {
      type = types.listOf types.path;
      description = "Any extra patches to be applied to the chaotic toolbox.";
      default = [ ];
    };
    useACMEHost = mkOption { default = null; };
    cluster = mkOption { default = false; };
  };

  config = mkIf cfg.enable {
    users.groups = {
      "chaotic_op" = {
        gid = lib.mkIf garuda-lib.unifiedUID 2000;
      };
    };
    environment.systemPackages = [
      toolbox
      arch-install-scripts
      pkgs.git
      pkgs.pacman
      repoctl
      pkgs.screen
      pkgs.gnupg
      telegram-send
    ];
    environment.etc = {
      "pacman.conf".text = ''
        [options]
        Architecture = x86_64
        SigLevel = Never
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

        # CDN
        # By: Garuda Linux
        Server = https://cdn-mirror.chaotic.cx/$repo/$arch
      '';
      "chaotic.conf".text = ''
        export CAUR_DB_NAME=${cfg.db-name}
        export CAUR_DEPLOY_PKGS=${repodir}/x86_64
        export CAUR_DEPLOY_LOGS=${repodir}/logs
        export CAUR_DEPLOY_LOGS_FILTERED=$CAUR_DEPLOY_LOGS/filtered
        export CAUR_DEPLOY_LAST=${repodir}/lastupdate

        ${optionalString (!cfg.cluster) ''
          export CAUR_URL=http://${cfg.host}/''${CAUR_DB_NAME}/x86_64
          export CAUR_FILL_DEST=http://${cfg.host}/''${CAUR_DB_NAME}/pkgs.files.txt
        ''}
        export CAUR_CLUSTER_NAME=${cfg.cluster-name}
        export CAUR_ROUTINES=/var/cache/chaotic/routines

        export REPOCTL_CONFIG=/etc/xdg/repoctl/config.toml
        export CAUR_GPG_PATH="${pkgs.gnupg}/bin/gpg"

        ${cfg.extraConfig}

        renice -n 19 $$ >/dev/null
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
    systemd.services = lib.mkMerge [
      {
        chaotic-setup = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          description = "Chaotic setup";
          path = [ pkgs.git pkgs.pacman pkgs.gnupg ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "execstart" ''
              set -e
              if [ ! -d "/var/lib/chaotic" ]; then mkdir "/var/lib/chaotic"; fi
              if [ ! -d "/var/lib/chaotic/packages" ]; then git clone "${cfg.packages}" /var/lib/chaotic/packages; fi
              if [ ! -d "/var/lib/chaotic/interfere" ]; then git clone "${cfg.interfere}" /var/lib/chaotic/interfere; fi
              if [ ! -d "/etc/pacman.d/gnupg" ]; then pacman-key --init; fi
              mkdir -p "${repodir}/x86_64"
              mkdir -p "${repodir}/logs"
            '';
          };
        };
      }
      (builtins.listToAttrs (builtins.map
        (x: {
          name = "chaotic-" + x;
          value = {
            description = "Chaotic's ${x} routine";
            serviceConfig = {
              User = "root";
              Group = "chaotic_op";
              WorkingDirectory = "/tmp";
              ExecStart = "${toolbox}/bin/chaotic routine ${x}";
              TimeoutStopSec = 86400;
              TimeoutStopFailureMode = "abort";
              WatchdogSignal = "SIGUSR1";
              TimeoutAbortSec = 600;
              CPUWeight = 50;
              MemoryHigh = "40G";
              MemoryMax = "42G";
              Nice = 19;
            };
          };
        })
        cfg.routines))
    ];
    systemd.timers = builtins.listToAttrs (builtins.map
      (x: {
        name = "chaotic-" + x;
        value = {
          description = "Chaotic's ${x} routine";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar =
              lib.attrByPath [ x ] (abort "Routine not defined in calendarmap")
                cfg.calendarmap;
            Persistent = false;
          };
        };
      })
      cfg.routines);
    security.wrappers = {
      chaotic = {
        setuid = true;
        owner = "root";
        group = "chaotic_op";
        source = "${toolbox}/bin/chaotic";
        permissions = "u+rx,g+rx,o-rx";
      };
    };
    services.nginx.enable = !cfg.cluster;
    services.nginx.virtualHosts.${cfg.host} = mkIf (!cfg.cluster) {
      extraConfig = ''
        autoindex on;
        autoindex_exact_size off;
      '';
      root = cfg.repos-dir;
      inherit (cfg) useACMEHost;
    };
    networking.hosts = mkIf (!cfg.cluster) { "127.0.0.1" = [ cfg.host ]; };

    # Handy aliases for our maintainers
    programs.bash = {
      interactiveShellInit = ''
        cb () {
          cg $@ && cmkd $@;
        }
      '';
      shellAliases = {
        "cg" = "chaotic get";
        "cmkd" = "chaotic -j 12 mkd";
        "crm" = "chaotic rm";
      };
    };
    programs.fish = {
      shellAbbrs = {
        "cg" = "chaotic get";
        "cmkd" = "chaotic -j 12 mkd";
        "crm" = "chaotic rm";
      };
    };
  };
  imports = [ ./chaotic-mirror.nix ];
}
