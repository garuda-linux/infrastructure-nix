{ pkgs, lib, garuda-lib, config, meshagent, ... }: {
  imports = [
    ./users.nix
    ./acme.nix
    ./nginx.nix
  ];
  networking.nameservers = [ "1.1.1.1" ];
  time.timeZone = "Europe/Berlin";

  zramSwap.enable = true;
  services.earlyoom = {
    enable = true;
    reeSwapThreshold = 5;
    freeMemThreshold = 5;
  };
  services.locate = {
    enable = true;
    locate = pkgs.plocate;
    localuser = null;
  };
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  programs.mosh.enable = true;
  programs.tmux = {
      clock24 = true;
      enable = true;
      extraConfig = "set-option -g base-index 1\nset-window-option -g pane-base-index 1";
      historyLimit = 10000; 
      plugins = [ pkgs.tmuxPlugins.continuum ];
      terminal = "screen-256color";
    };
  environment.variables = { MOSH_SERVER_NETWORK_TMOUT="604800"; };

  # TODO: Move this to a security.nix
  # Timeout TTY after 1 hour
  programs.bash.interactiveShellInit = ''if [[ $(tty) =~ /dev\/tty[1-6] ]]; then TMOUT=3600; fi'';
  programs.fish = {
      enable = true;
      #shellAlises = 
      shellInit = "set fish_greeting";
  };
  console.keyMap = "de";

  services.garuda-meshagent.enable = lib.mkDefault true;
  services.garuda-meshagent.mshFile = garuda-lib.secrets.meshagent_msh;
  services.garuda-meshagent.agentBinary = if pkgs.hostPlatform.system == "aarch64-linux" then meshagent.aarch64 else meshagent.x86_64;

  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.autoPrune.flags = [ "-a" ];

  environment.systemPackages = with pkgs; [ python3 micro htop git screen ugrep ];

  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ garuda-lib.secrets.zerotier_network ];

  services.garuda-monitoring.enable = true;
  services.garuda-monitoring.parent = "10.241.0.10";

  services.vnstat.enable = true; 

  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 2d";
  };
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.package = pkgs.unstable.nix;
  documentation.nixos.enable = false;
}
