{ config
, pkgs
, ...
}: {
  # Always needed home-manager settings - don't touch!
  home.username = "nico";
  home.homeDirectory = "/home/nico";
  home.stateVersion = "22.05";

  # Personally used packages
  home.packages = with pkgs; [ btop nmap nettools bind whois traceroute lynis ];

  # Application user configuration
  programs = {
    bash = {
      enable = true;
      initExtra = ''
        if [ "$SSH_CLIENT" != "" ]; then
          exec ${pkgs.tmux}/bin/tmux attach
        fi
      '';
    };
    bat = {
      enable = true;
      config = { theme = "GitHub"; };
    };
    btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        proc_tree = true;
        theme_background = false;
      };
    };
    exa = {
      enable = true;
      enableAliases = true;
    };
    fish = {
      enable = true;
      shellInit = ''
        # Motd
        ${pkgs.fancy-motd}/bin/motd
      '';
    };
    git = {
      enable = true;
      extraConfig = {
        core = { editor = "micro"; };
        init = { defaultBranch = "main"; };
        pull = { rebase = true; };
      };
      userEmail = "root@dr460nf1r3.org";
      userName = "Nico Jensch";
    };
    tmux = {
      baseIndex = 1;
      clock24 = true;
      enable = true;
      extraConfig = ''
        set-option -ga terminal-overrides ",*256col*:Tc,alacritty:Tc"
      '';
      historyLimit = 10000;
      newSession = true;
      sensibleOnTop = false;
      shell = "${pkgs.fish}/bin/fish";
    };
  };
}
