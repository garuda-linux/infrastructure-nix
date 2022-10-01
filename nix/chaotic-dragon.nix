{ config, garuda-lib, pkgs, ... }: {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "chaotic-dragon";
  networking.interfaces."eth0".ipv4.addresses = [{
    address = "192.168.1.50";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  boot.loader.initScript.enable = true;
  boot.isContainer = true;
  systemd.enableUnifiedCgroupHierarchy = false;

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "garuda-repo";
  services.chaotic.host = "repo.garudalinux.org";
  services.chaotic.extraConfig = ''
    export CAUR_SIGN_KEY=BF773B6877808D28
    export CAUR_SIGN_USER=root
    export CAUR_PACKAGER="Nico Jensch <dr460nf1r3@chaotic.cx>"
    export CAUR_TYPE=cluster
    export CAUR_URL=https://builds.garudalinux.org/repos/chaotic-aur/x86_64

    export CAUR_CLUSTER_NAME=dragon-cluster
    export CAUR_DEPLOY_LABEL="Chaotic Dragon 🐉"
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"

    export CAUR_REPOCTL_DB_URL=https://builds.garudalinux.org/repos/chaotic-aur/x86_64/chaotic-aur.db.tar.zst
    export CAUR_REPOCTL_DB_FILE=/tmp/chaotic/db.tar.zst
  '';
  services.chaotic.db-name = "chaotic-aur";
  services.chaotic.routines = [ "hourly" "nightly" "afternoon" "tkg-wine" ];
  services.chaotic.cluster = true;

  # Chaotic-AUR mirror
  services.chaotic-mirror.enable = true;
  services.chaotic-mirror.email = "team@garudalinux.org";
  services.chaotic-mirror.domain = "chaotic.dr460nf1r3.org";

  system.stateVersion = "22.05";
}
