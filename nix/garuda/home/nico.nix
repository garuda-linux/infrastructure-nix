{ config, pkgs, lib, ... }:

{
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
        if [ "$SSH_CLIENT" != "" ] && [ -z "$TMUX" ]; then
          exec tmux
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
        theme_background = false;
        proc_tree = true;
      };
    };  
    exa = {
      enable = true;
      enableAliases = true;
    };
    fish = { enable = true; };
    git = {
      enable = true;
      userEmail = "root@dr460nf1r3.org";
      userName = "Nico Jensch";
      extraConfig = {
        core = { editor = "micro"; };
        pull = { rebase = true; };
        init = { defaultBranch = "main"; };
      };
    };
    starship = {
      enable = true;
      settings = {
        username = {
          format = " [$user]($style)@";
          style_user = "bold red";
          style_root = "bold red";
          show_always = true;
        };
        hostname = {
          format = "[$hostname]($style) in ";
          style = "bold dimmed red";
          trim_at = "-";
          ssh_only = false;
          disabled = false;
        };
        scan_timeout = 10;
        directory = {
          style = "purple";
          truncation_length = 0;
          truncate_to_repo = true;
          truncation_symbol = "repo: ";
        };
        status = {
          map_symbol = true;
          disabled = false;
        };
        sudo = { disabled = false; };
        cmd_duration = {
          min_time = 1;
          format = "took [$duration]($style)";
          disabled = false;
        };
      };
    };
    tmux = {
      clock24 = true;
      enable = true;
      plugins = with pkgs; [ tmuxPlugins.continuum ];
      extraConfig = ''
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '60'
      '';
      historyLimit = 10000;
      baseIndex = 1;
      terminal = "screen-256color";
      shell = "${pkgs.fish}/bin/fish";
    };
  };
}
