{ pkgs, ... }:
{
  # Always needed home-manager settings - don't touch!
  home.username = "nico";
  home.homeDirectory = "/home/nico";
  home.stateVersion = "25.05";

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
      config = {
        theme = "Dracula";
      };
    };
    btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        proc_tree = false;
        theme_background = false;
      };
    };
    fish = {
      enable = true;
    };
    git = {
      difftastic.enable = true;
      enable = true;
      extraConfig = {
        core = {
          editor = "micro";
        };
        init = {
          defaultBranch = "main";
        };
        pull = {
          rebase = true;
        };
      };
      userEmail = "root@dr460nf1r3.org";
      userName = "Nico Jensch";
    };
    tmux = {
      baseIndex = 1;
      clock24 = true;
      enable = true;
      extraConfig = ''
        set -g default-terminal "screen-256color"
        set -g status-bg black
      '';
      historyLimit = 100000;
      newSession = true;
      sensibleOnTop = false;
      shell = "${pkgs.fish}/bin/fish";
    };
  };
}
