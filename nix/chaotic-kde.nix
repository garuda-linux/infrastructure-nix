{ garuda-lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "kde-git";
  services.chaotic.host = "kde-git.chaotic.cx";
  services.chaotic.extraConfig = ''
    export CAUR_DEPLOY_LABEL="KDE Dragon 🐉"
    export CAUR_LOWER_PKGS+=(chaotic-mirrorlist chaotic-keyring git qt6-declarative qt6-tools qt6-doc clang doxygen qt6-declarative)
    export CAUR_PACKAGER="Nico Jensch <dr460nf1r3@chaotic.cx>"
    export CAUR_SIGN_KEY=0706B90D37D9B881
    export CAUR_SIGN_USER=nico
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"
  '';
  services.chaotic.db-name = "chaotic-aur-kde";
  services.chaotic.routines = [ "hourly" "nightly" "afternoon" ];
  services.chaotic.patches = [ ./garuda/services/chaotic/add-chaotic-repo.diff ./garuda/services/chaotic/prepend-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  # Special Syncthing configuration allowing to push to main node
  # services.syncthing = {
  #   enable = true;
  #   overrideDevices = true;
  #   overrideFolders = true;
  #   configDir = config.services.syncthing.dataDir;
  #   inherit (garuda-lib.secrets.syncthing.kde-dragon) cert;
  #   inherit (garuda-lib.secrets.syncthing.kde-dragon) key;
  #   devices = {
  #     "builds.garudalinux.org" = {
  #       inherit (garuda-lib.secrets.syncthing.esxi-build) id;
  #       addresses = [ "dynamic" "tcp://builds.garudalinux.org" ];
  #     };
  #   };
  #   folders = {
  #     "chaotic-aur-kde" = {
  #       path = "/srv/http/repos/chaotic-aur-kde";
  #       id = garuda-lib.secrets.syncthing.folders.chaotic-aur-kde;
  #       devices = [ "builds.garudalinux.org" ];
  #       type = "sendonly";
  #     };
  #   };
  #   extraOptions = {
  #     gui = {
  #       apikey = "garudalinux";
  #       insecureSkipHostcheck = true;
  #     };
  #   };
  # };

  # Cloudflared access to Syncthing webinterface
  # services.garuda-cloudflared = {
  #   enable = true;
  #   ingress = { "syncthing-kde.garudalinux.net" = "http://localhost:8384"; };
  #   tunnel-credentials = garuda-lib.secrets.cloudflare.cloudflared.kde-dragon.cred;
  # };

  # Auto reset syncthing stuff
  /*systemd.services.syncthing-reset = {
    serviceConfig.Type = "oneshot";
    script = ''
      "${pkgs.curl}/bin/curl" -X POST -H "X-API-Key: garudalinux" http://localhost:8384/rest/db/override?folder=${garuda-lib.secrets.syncthing.folders.chaotic-aur-kde}
    '';
    };
    systemd.timers.syncthing-reset = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = [ "hourly" ];
  };*/

  # Fix nix nonsense causing issues with not being able to mount /proc
  /*systemd.services.create-tmp-proc-directory = {
    description = "Create /tmp/proc directory";
    script = ''
      mkdir -p /tmp/proc
    '';
    };
    systemd.mounts = [{
    description = "Mount for procfs to /tmp/proc";
    what = "none";
    where = "/tmp/proc";
    type = "proc";
    requires = [ "create-tmp-proc-directory.service" ];
    after = [ "create-tmp-proc-directory.service" ];
    wantedBy = [ "multi-user.target" ];
  }];*/

  system.stateVersion = "23.05";
}

