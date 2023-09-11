{ pkgs, ... }: {
  # Always needed home-manager settings - don't touch!
  home.username = "alexjp";
  home.homeDirectory = "/home/alexjp";
  home.stateVersion = "22.05";

  # Application user configuration
  programs = {
    bash = {
      enable = true;
      initExtra = ''
        if [ "$SSH_CLIENT" != "" ] && [ -z "$TMUX" ]; then
          exec ${pkgs.tmux}/bin/tmux
        fi
      '';
    };
    bat = {
      enable = true;
      config.theme = "GitHub";
    };
    fish.enable = true;
    git = {
      enable = true;
      userEmail = "programming.hubmaking@slmail.me";
      userName = "Alex JP";
      extraConfig = {
        core = { editor = "nvim"; };
        init = { defaultBranch = "main"; };
        pull = { rebase = true; };
      };
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
