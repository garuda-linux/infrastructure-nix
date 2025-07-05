{
  config,
  garuda-lib,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  # Network stuff - DNS gets overridden by Tailscale magic DNS
  networking = lib.mkIf (!garuda-lib.minimalContainer) {
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    useDHCP = false;
    usePredictableInterfaceNames = true;
  };

  ## Enable BBR & cake
  boot.kernelModules = lib.mkIf (!garuda-lib.minimalContainer) [ "tcp_bbr" ];
  boot.kernel.sysctl = lib.mkIf (!garuda-lib.minimalContainer) {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    # Make cloudflared happy (https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size)
    "net.core.rmem_max" = 2500000;
  };
  # Mount /run as shared for systemd-nspawn
  boot.specialFileSystems."/run".options = lib.mkIf (!config.boot.isContainer) [ "rshared" ];

  # Locales & timezone
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [
      "en_GB.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
    ];
  };
  console.keyMap = "de";

  # Clean /tmp on boot
  boot.tmp.cleanOnBoot = true;

  # Home-manager configuration
  home-manager = lib.mkIf (!garuda-lib.minimalContainer) {
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      alexjp = import ../../home-manager/alexjp.nix;
      nico = import ../../home-manager/nico.nix;
    };
  };

  # Programs & global config
  programs.bash.shellAliases = {
    "bat" = "bat --style header --style snip --style changes";
    "cls" = "clear";
    "dir" = "dir --color=auto";
    "egrep" = "egrep --color=auto";
    "fgrep" = "fgrep --color=auto";
    "ip" = "ip --color=auto";
    "ls" = "eza -al --color=always --group-directories-first --icons";
    "micro" = "micro -colorscheme geany -autosu true -mkparents true";
    "psmem" = "ps auxf | sort -nr -k 4";
    "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
    "su" = "sudo su -";
    "tarnow" = "tar acf ";
    "untar" = "tar zxvf ";
    "vdir" = "vdir --color=auto";
    "wget" = "wget -c";
  };
  programs.command-not-found.enable = false;
  programs.fish = {
    enable = true;
    shellAbbrs = {
      "cls" = "clear";
      "reb" = "sudo nixos-rebuild switch -L";
      "roll" = "sudo nixos-rebuild switch --rollback";
      "su" = "sudo su -";
    };
    shellAliases = {
      "bat" = "bat --style header --style snip --style changes";
      "dir" = "dir --color=auto";
      "egrep" = "egrep --color=auto";
      "fgrep" = "fgrep --color=auto";
      "ip" = "ip --color=auto";
      "ls" = "eza -al --color=always --group-directories-first --icons";
      "micro" = "micro -colorscheme geany -autosu true -mkparents true";
      "psmem" = "ps auxf | sort -nr -k 4";
      "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
      "tarnow" = "tar acf ";
      "untar" = "tar zxvf ";
      "vdir" = "vdir --color=auto";
      "wget" = "wget -c";
    };
    shellInit = ''
      set fish_greeting
    '';
  };

  # This does not work in containers
  programs.mosh.enable = lib.mkIf (!garuda-lib.minimalContainer) true;

  # Services
  services = {
    garuda-monitoring.enable = lib.mkIf (!garuda-lib.minimalContainer) true;
    garuda-tailscale.enable = lib.mkIf (!garuda-lib.minimalContainer) true;
    locate = {
      enable = true;
      package = pkgs.plocate;
    };
    openssh.enable = true;
    vnstat.enable = true;
  };

  # OOM prevention
  systemd.oomd = {
    enable = true; # This is actually the default, anyways...
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # Docker
  virtualisation.docker = {
    autoPrune = {
      enable = true;
      flags = [ "-a" ];
    };
  };

  # Environment
  environment = {
    # Fix for Ghostty acting weird (https://ghostty.org/docs/help/terminfo)
    enableAllTerminfo = true;
    # Packages the system needs, individual user packages shall be put into home-manager configurations
    systemPackages = with pkgs; [
      btop
      cachix
      eza
      fancy-motd
      fishPlugins.autopair
      fishPlugins.puffer
      git
      goaccess
      htop
      jq
      killall
      micro
      gdu
      python3
      screen
      ugrep
      wget

      # Alexjp stuff
      cargo
      neovim
      nushell
      rustc
    ];
    # Increase Mosh timeout
    variables = {
      MOSH_SERVER_NETWORK_TMOUT = "604800";
    };
  };

  # General nix settings
  nix = {
    settings = {
      # Allow using flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      substituters = [ "https://garuda-linux.cachix.org" ];
      trusted-public-keys = lib.mkAfter [
        "garuda-linux.cachix.org-1:tWw7YBE6qZae0L6BbyNrHo8G8L4sHu5QoDp0OXv70bg="
      ];
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
    package = pkgs.lixPackageSets.latest.lix;
  };

  # Do daily garbage collection
  programs.nh = {
    enable = true;
    clean = {
      enable = true;
      extraArgs = "--keep-since 2d";
      dates = "daily";
    };
    flake = "/etc/nixos";
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Disable generation of manpages
  documentation.man.enable = false;

  # Print a diff when running system updates
  system.activationScripts.diff = lib.mkIf (!garuda-lib.minimalContainer) ''
    if [[ -e /run/current-system ]]; then
      (
        for i in {1..3}; do
          result=$(${config.nix.package}/bin/nix store diff-closures /run/current-system "$systemConfig" 2>&1)
          if [ $? -eq 0 ] && [ ! -z "$result" ]; then
            printf '%s\n' "$result"
            break
          fi
        done
      )
    fi
  '';

  # Workaround https://discourse.nixos.org/t/logrotate-config-fails-due-to-missing-group-30000/28501
  # for now
  services.logrotate.checkConfig = false;

  # Secrets management
  sops = {
    defaultSopsFile = ../../secrets/shared.yaml;
    age.sshKeyPaths = [ garuda-lib.sshkeys.ed25519 ];
  };
}
