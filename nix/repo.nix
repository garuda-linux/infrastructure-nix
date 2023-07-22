{ sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "garuda-repo";
  services.chaotic.host = "repo.garudalinux.org";
  services.chaotic.extraConfig = ''
    export CAUR_DEPLOY_LABEL="Maximus 🐉"
    export CAUR_LOWER_PKGS+=(chaotic-mirrorlist chaotic-keyring)
    export CAUR_PACKAGER="Garuda Builder <team@garudalinux.org>"
    export CAUR_SIGN_KEY=D6C9442437365605
    export CAUR_ROUTINES=/tmp/chaotic/routines
    export CAUR_SIGN_USER=root
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"

    export HTTP_PROXY=http://10.0.5.1:3128/
    export HTTPS_PROXY=http://10.0.5.1:3128/
    export NO_PROXY=mirror.rackspace.com,cloudflaremirrors.com,github.com
  '';
  services.chaotic.db-name = "garuda";
  services.chaotic.routines = [ "hourly" ];
  services.chaotic.patches = [ ./garuda/services/chaotic/add-chaotic-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  system.stateVersion = "23.05";
}

