{ config, lib, garuda-lib, pkgs, ... }: {
  imports = [ ./garuda/garuda.nix ./garuda/common/lxc.nix ];

  # Base configuration
  networking.hostName = "kde-dragon";
  networking.interfaces."eth0".ipv4.addresses = [{
    address = "192.168.1.90";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  systemd.enableUnifiedCgroupHierarchy = lib.mkForce true;

  # Openssh HPN for the performance gains while uploading packages
  programs.ssh.package = pkgs.openssh_hpn;

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "kde-git";
  services.chaotic.host = "kde-git.chaotic.cx";
  services.chaotic.extraConfig = ''
    export CAUR_DEPLOY_LABEL="KDE Dragon 🐉"
    export CAUR_LOWER_PKGS+=(chaotic-mirrorlist chaotic-keyring)
    export CAUR_PACKAGER="Nico Jensch <dr460nf1r3@chaotic.cx>"
    export CAUR_SIGN_KEY=0706B90D37D9B881
    export CAUR_SIGN_USER=nico
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"
  '';
  services.chaotic.db-name = "chaotic-aur-kde";
  services.chaotic.routines = [ "hourly" "nightly" "afternoon" ];
  services.chaotic.patches = [ ./garuda/services/chaotic/kde-git.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  # Netdata would not send data via Zerotier, hence we access the local IP (same host)
  services.netdata.configDir = lib.mkForce {
    "go.d.conf" = pkgs.writeText "go.d.conf" ''
      enabled: yes
      modules:
        nginx: yes
        postgres: yes
        vsphere: yes
        web_log: yes
    '';
    "python.d.conf" = pkgs.writeText "python.d.conf" ''
      postgres: no
      web_log: no
    '';
    "go.d/nginx.conf" = (pkgs.writeText "nginx.conf" ''
      jobs:
        - name: local
          url: http://localhost/nginx_status
    '');
    "stream.conf" = pkgs.writeText "stream.conf" ''
      [stream]
          api key = ${garuda-lib.secrets.netdata.stream_token}
          buffer size bytes = 15728640
          destination = 192.168.1.80
          enable compression = yes
          enabled = yes
          timeout seconds = 360

      [logs]
          debug log = none
          error log = none
          access log = none
    '';
  };

  system.stateVersion = "22.11";
}
