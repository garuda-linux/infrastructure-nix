{ sources, ... }: {
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
    export CAUR_PACKAGER="Garuda Builder <team@garudalinux.org>"
    export CAUR_ROUTINES=/tmp/chaotic/routines
    export CAUR_SIGN_KEY=0706B90D37D9B881
    export CAUR_SIGN_USER=root
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"

    export HTTP_PROXY=http://10.0.5.1:3128/
    export HTTPS_PROXY=http://10.0.5.1:3128/
    export NO_PROXY=mirror.rackspace.com,cloudflaremirrors.com,github.com
  '';
  services.chaotic.db-name = "chaotic-aur-kde";
  services.chaotic.routines = [ "hourly" "nightly" "afternoon" ];
  services.chaotic.patches = [ ./garuda/services/chaotic/add-chaotic-repo.diff ./garuda/services/chaotic/prepend-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  system.stateVersion = "23.05";
}

