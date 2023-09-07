{ pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "kde-git";
  services.chaotic.host = "kde-git.chaotic.cx";
  services.chaotic.extraConfig = ''
    export CAUR_DEPLOY_LABEL="KDE Dragon 🐉"
    export CAUR_LOWER_PKGS+=(chaotic-mirrorlist chaotic-keyring git qt6-declarative qt6-tools qt6-doc clang doxygen qt6-declarative)
    export CAUR_PACKAGER="Garuda Builder <team@garudalinux.org>"
    export CAUR_ROUTINES=/tmp/chaotic/routines
    export CAUR_SIGN_KEY=D6C9442437365605
    export CAUR_SIGN_USER=root
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"

    export GIT_SSH_COMMAND="ssh -i /var/garuda/secrets/chaotic/interfere_ed25519"
    export HTTP_PROXY=http://10.0.5.1:3128/
    export HTTPS_PROXY=http://10.0.5.1:3128/
    export NO_PROXY=mirror.rackspace.com,cloudflaremirrors.com,github.com,downloads.sentry-cdn.com
  '';
  services.chaotic.db-name = "chaotic-aur-kde";
  services.chaotic.routines = [ "hourly" "nightly" "afternoon" ];
  services.chaotic.patches = [ ../services/chaotic/add-chaotic-repo.diff ../services/chaotic/prepend-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  # Allow systemd-nspawn to create subcgroups (for Chaotic-AUR builders)
  systemd.services.remount-sysfscgroup = {
    description = "Remount cgroup2 to allow systemd-nspawn to create subcgroups";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.mount}/bin/mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup
    '';
  };

  system.stateVersion = "23.05";
}

