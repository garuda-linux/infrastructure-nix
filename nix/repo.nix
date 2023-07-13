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
    export CAUR_SIGN_USER=nico
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"
  '';
  services.chaotic.db-name = "garuda";
  services.chaotic.routines = [ "hourly" ];
  services.chaotic.patches = [ ./garuda/services/chaotic/add-chaotic-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  # Fix nix nonsense causing issues with not being able to mount /proc
  systemd.services.create-tmp-proc-directory = {
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
  }];

  system.stateVersion = "23.05";
}

