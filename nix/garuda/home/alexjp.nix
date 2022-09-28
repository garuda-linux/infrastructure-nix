{ config, pkgs, lib, ... }:

{
  # Always needed home-manager settings - don't touch!
  home.username = "alexjp";
  home.homeDirectory = "/home/alexjp";
  home.stateVersion = "22.05";

  # Personally used packages
  home.packages = with pkgs; [ neovim ];

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
    exa = {
      enable = true;
      enableAliases = true;
    };
    fish = { enable = true; };
    git = {
      enable = true;
      userEmail = "programming.hubmaking@slmail.me";
      userName = "Alex JP";
      extraConfig = {
        core = { editor = "nvim"; };
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

  # Services that should be running
  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
}
