{ pkgs, lib, garuda-lib, config, meshagent, ... }: {
  imports = [ ./acme.nix ./hardening.nix ./motd.nix ./nginx.nix ./users.nix ];

  # Network stuff
  networking = {
    nameservers = [ "1.1.1.1" ];
    useDHCP = false;
    usePredictableInterfaceNames = true;
  };

  # Locales & timezone
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [ "en_GB.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };
  console = {
    keyMap = "de";
    font = "Lat2-Terminus18";
  };

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
  programs.fish = {
    enable = true;
    shellAbbrs = {
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
      "su" = "sudo su -";
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
    openssh.enable = true;
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
      joinNetworks = [ garuda-lib.secrets.zerotier_network ];
    };
    garuda-monitoring = {
      enable = true;
      parent = "10.241.0.10";
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

  # Docker
  virtualisation.docker = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
  };

  # Environment
  environment = {
    # Packages the system needs, individual user packages shall be put into home-manager configurations
    systemPackages = with pkgs; [ python3 micro htop git screen fancy-motd ];
    # Increase Mosh timeout
    variables = { MOSH_SERVER_NETWORK_TMOUT = "604800"; };
  };

  # General nix settings
  nix = {
    # Do daily garbage collections
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };
    # Idk what this does
    package = pkgs.unstable.nix;
    # Allow using flakes
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  systemd.services.nix-clean-result = {
    serviceConfig.Type = "oneshot";
    description =
      "Auto clean all result symlinks created by nixos-rebuild test";
    script = ''
      "${config.nix.package.out}/bin/nix-store" --gc --print-roots | "${pkgs.gawk}/bin/awk" 'match($0, /^(.*\/result) -> \/nix\/store\/[^-]+-nixos-system/, a) { print a[1] }' | xargs -d\\n rm
    '';
    before = [ "nix-gc.service" ];
    wantedBy = [ "nix-gc.service" ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Disable generation of manpages
  documentation.man.enable = false;
}
