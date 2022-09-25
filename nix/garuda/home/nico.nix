{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "nico";
  home.homeDirectory = "/home/nico";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";

  #home.packages = [ pkgs.tmux ];

  programs.starship = {
    enable = true;
    #settings = {
    #  add_newline = false;
    #  format = lib.concatStrings [
    #    "$line_break"
    #    "$package"
    #    "$line_break"
    #    "$character"
    #  ];
    #  scan_timeout = 10;
    #  character = {
    #    success_symbol = "➜";
    #    error_symbol = "➜";
    #  };
    enableFishIntegration = true;
    };

  programs.bash = {
    enable = true; 
    initExtra = ''
      if [ "$SSH_CLIENT" != "" ] && [ -z "$TMUX" ]; then
        exec tmux
      fi
      '';
  };
   programs.tmux = {
      clock24 = true;
      enable = true;
      plugins = [ pkgs.tmuxPlugins.continuum ];
      historyLimit = 10000;
      baseIndex = 1; 
      terminal = "screen-256color";
      shell = "${pkgs.fish}/bin/fish";
  }; 

  programs.fish = {
    enable = true;
  };

  programs.git = {
    enable = true;
    userEmail = "root@dr460nf1r3.org";
    userName = "Nico Jensch";
    extraConfig = {
      core = {
        editor = "micro";
      };
      pull = {
        rebase = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  services.gpg-agent = {                          
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };
/*   programs.micro.enable = true; 
  programs.micro.settings = ''
  {
   "autosu": true,
   "colorscheme": "geany",
   "mkparents": true
  }
  ''; */
}