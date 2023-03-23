{ pkgs, lib, garuda-lib, config, meshagent, sources, ... }: {
  imports = [ ./acme.nix ./hardening.nix ./motd.nix ./nginx.nix ./users.nix ];

  # Network stuff
  networking = {
    nameservers = [ "1.1.1.1" ];
    useDHCP = false;
    usePredictableInterfaceNames = true;
    firewall.trustedInterfaces = [ garuda-lib.secrets.zerotier.interface ];
    useHostResolvConf = false;
    useNetworkd = true;
  };
  systemd.network = {
    networks = {
      "${garuda-lib.secrets.zerotier.interface}" = {
        name = "${garuda-lib.secrets.zerotier.interface}";
        networkConfig = {
          MulticastDNS = true;
          LinkLocalAddressing = "no";
          KeepConfiguration = true;
        };
      };
    };
  };
  services.resolved.enable = true;
  services.resolved.extraConfig = "MulticastDNS=true";

  ## Enable BBR & cake
  boot.kernelModules = [ "tcp_bbr" ];
  boot.kernel.sysctl = {
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
  };
  # Mount /run as shared for systemd-nspawn
  boot.specialFileSystems."/run".options = lib.mkIf (!config.boot.isContainer) [ "rshared" ];

  # Locales & timezone
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [ "en_GB.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };
  console = { keyMap = "de"; };

  boot.cleanTmpDir = true;

  # Home-manager configuration
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nico = import ../home/nico.nix;
    users.alexjp =
      lib.mkIf config.services.chaotic.enable (import ../home/alexjp.nix);
  };

  # Programs & global config
  programs.mosh.enable = true;
  programs.bash.shellAliases = {
    "bat" = "bat --style header --style snip --style changes";
    "cls" = "clear";
    "dir" = "dir --color=auto";
    "egrep" = "egrep --color=auto";
    "fgrep" = "fgrep --color=auto";
    "ip" = "ip --color=auto";
    "ls" = "exa -al --color=always --group-directories-first --icons";
    "micro" = "micro -colorscheme geany -autosu true -mkparents true";
    "psmem" = "ps auxf | sort -nr -k 4";
    "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
    "su" = "sudo su -";
    "tarnow" = "tar acf ";
    "untar" = "tar zxvf ";
    "vdir" = "vdir --color=auto";
    "wget" = "wget -c";
  };
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
      "ls" = "exa -al --color=always --group-directories-first --icons";
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

  # Services 
  services = {
    vnstat.enable = true;
    openssh = {
      enable = true;
      startWhenNeeded = true;
    };
    garuda-meshagent = {
      agentBinary = if pkgs.hostPlatform.system == "aarch64-linux" then
        meshagent.aarch64
      else
        meshagent.x86_64;
      enable = lib.mkDefault true;
      mshFile = garuda-lib.secrets.meshagent_msh;
    };
    zerotierone = {
      enable = true;
      joinNetworks = [ garuda-lib.secrets.zerotier.network ];
    };
    garuda-monitoring = {
      enable = true;
      parent = "monitor-dragon.local";
    };
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
      freeSwapThreshold = 5;
    };
    locate = {
      enable = true;
      localuser = null;
      locate = pkgs.plocate;
    };
  };
  services.zerotierone.package = pkgs.zerotierone.overrideAttrs (finalAttrs: previousAttrs: {
    doCheck = false;
  });

  # Docker
  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
  };

  # Environment
  environment = {
    # Packages the system needs, individual user packages shall be put into home-manager configurations
    systemPackages = with pkgs; [
      cachix
      exa
      fancy-motd
      git
      goaccess
      htop
      jq
      killall
      micro
      python3
      screen
      ugrep
      wget
    ];
    # Increase Mosh timeout
    variables = { MOSH_SERVER_NETWORK_TMOUT = "604800"; };
  };

  # General nix settings
  nix = {
    # Do garbage collections whenever there is less than 1GB free space left
    extraOptions = ''
      min-free = ${toString (1024 * 1024 * 1024)}
    '';
    # Do daily garbage collections
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };
    settings = {
      # Allow using flakes
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      substituters = [ "https://garuda-linux.cachix.org" ];
      trusted-public-keys = [ "garuda-linux.cachix.org-1:tWw7YBE6qZae0L6BbyNrHo8G8L4sHu5QoDp0OXv70bg=" ];
      builders-use-substitutes = true;
    };
    nixPath = [ "nixpkgs=${sources.nixpkgs}" ];
  };

  # Make cloudflared happy (https://github.com/lucas-clemente/quic-go/wiki/UDP-Receive-Buffer-Size)
  boot.kernel.sysctl = { "net.core.rmem_max" = 2500000; };
  services.cloudflared.user = "root";

  systemd.services.nix-clean-result = {
    serviceConfig.Type = "oneshot";
    description =
      "Auto clean all result symlinks created by nixos-rebuild test";
    script = ''
      "${config.nix.package.out}/bin/nix-store" --gc --print-roots | "${pkgs.gawk}/bin/awk" 'match($0, /^(.*\/result) -> \/nix\/store\/[^-]+-nixos-system/, a) { print a[1] }' | xargs -r -d\\n rm
    '';
    before = [ "nix-gc.service" ];
    wantedBy = [ "nix-gc.service" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Disable generation of manpages
  documentation.man.enable = false;

  # Print a diff when running system updates
  system.activationScripts.diff = ''
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

  # No need for sound on a server
  sound.enable = false;
}
