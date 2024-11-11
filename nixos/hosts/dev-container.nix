{ inputs
, lib
, keys
, pkgs
, ...
}:
{
  # No default modules, untrusted container!
  # imports = sources.defaultModules ++ [
  #   ./garuda/garuda.nix
  # ];

  imports = [
    ../modules/hardening.nix
    ../modules/motd.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Enable SSH
  services.openssh.enable = true;

  # No custom users - only Nico and root via nixos-container root-login
  users = {
    allowNoPasswordLogin = true;
    mutableUsers = false;
    users.nico = {
      home = "/home/nico";
      extraGroups = [ "podman" ];
      isNormalUser = true;
      shell = pkgs.bashInteractive;
      openssh.authorizedKeys.keyFiles = [ keys.nico ];
    };
  };
  home-manager = {
    users."nico" = {
      imports = [
        ../../home-manager/nico.nix
      ];
      home.stateVersion = lib.mkForce "24.05";
    };
    useGlobalPkgs = true;
  };

  # Common Docker configurations
  virtualisation.podman = {
    autoPrune.enable = true;
    autoPrune.flags = [ "-a" ];
    defaultNetwork.settings.dns_enabled = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    enable = true;
  };

  # Make Pedro god here
  nix.settings = {
    trusted-users = [ "nico" ];
    experimental-features = [ "nix-command" "flakes" ];
    builders-use-substitutes = true;
  };
  security.sudo.extraRules = [
    {
      users = [ "nico" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Further needed tools and tweaks
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    bat
    btop
    cmake
    deno
    distrobox
    distrobox-tui
    docker-compose
    eza
    fishPlugins.autopair
    fishPlugins.puffer
    gcc
    git
    gnumake
    jq
    micro
    nixd
    nodePackages_latest.pnpm
    nodejs_latest
    python3
    ugrep
    wget
    yarn-berry
  ];
  nixpkgs.config.allowUnfree = true;

  # Locales & timezone
  time.timeZone = "Europe/Berlin";
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [ "en_GB.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" ];
  };
  console.keyMap = "de";

  networking.hosts = {
    "127.0.0.1" = [ "metrics.chaotic.local" "backend.chaotic.local" ];
  };

  environment.sessionVariables = {
    DEV_CONTAINER = "1";
    EDITOR = "${pkgs.micro}/bin/micro";
    VISUAL = "${pkgs.micro}/bin/micro";
  };

  # Programs & global config
  programs = {
    bash.shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      "......" = "cd ../../../../../";
      "bat" = "bat --style header --style snip --style changes";
      "cat" = "bat --style header --style snip --style changes";
      "cls" = "clear";
      "dir" = "dir --color=auto";
      "egrep" = "egrep --color=auto";
      "fastfetch" = "fastfetch -l nixos";
      "fgrep" = "fgrep --color=auto";
      "gcommit" = "git commit -m";
      "gitlog" = "git log --oneline --graph --decorate --all";
      "glcone" = "git clone";
      "gpr" = "git pull --rebase";
      "gpull" = "git pull";
      "gpush" = "git push";
      "ip" = "ip --color=auto";
      "jctl" = "journalctl -p 3 -xb";
      "ls" = "eza -al --color=always --group-directories-first --icons";
      "psmem" = "ps auxf | sort -nr -k 4";
      "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
      "su" = "sudo su -";
      "tarnow" = "tar acf ";
      "tree" = "eza --git --color always -T";
      "untar" = "tar zxvf ";
      "vdir" = "vdir --color=auto";
      "wget" = "wget -c";
    };

    # Direnv for per-directory environment variables
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # The fish shell, default for terminals
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
      };
      shellAbbrs = {
        ".." = "cd ..";
        "..." = "cd ../../";
        "...." = "cd ../../../";
        "....." = "cd ../../../../";
        "......" = "cd ../../../../../";
        "cls" = "clear";
        "gcommit" = "git commit -m";
        "glcone" = "git clone";
        "gpr" = "git pull --rebase";
        "gpull" = "git pull";
        "gpush" = "git push";
        "run" = "comma ";
        "su" = "sudo su -";
        "tarnow" = "tar acf ";
        "tree" = "eza --git --color always -T";
        "untar" = "tar zxvf ";
        "use" = "nix shell nixpkgs#";
      };
      shellAliases = {
        "bat" = "bat --style header --style snip --style changes";
        "cat" = "bat --style header --style snip --style changes";
        "dir" = "dir --color=auto";
        "egrep" = "egrep --color=auto";
        "fastfetch" = "fastfetch -l nixos";
        "fgrep" = "fgrep --color=auto";
        "gitlog" = "git log --oneline --graph --decorate --all";
        "ip" = "ip --color=auto";
        "jctl" = "journalctl -p 3 -xb";
        "ls" = "eza -al --color=always --group-directories-first --icons";
        "psmem" = "ps auxf | sort -nr -k 4";
        "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
        "vdir" = "vdir --color=auto";
        "wget" = "wget -c";
      };
      shellInit = ''
        set fish_greeting
        ${pkgs.fastfetch}/bin/fastfetch
      '';
    };

    # The starship prompt
    starship = {
      enable = true;
      settings = {
        aws.symbol = "  ";
        buf.symbol = " ";
        c.symbol = " ";
        cmd_duration = {
          disabled = false;
          format = "took [$duration]($style)";
          min_time = 1;
        };
        conda.symbol = " ";
        crystal.symbol = " ";
        dart.symbol = " ";
        directory = {
          read_only = " 󰌾";
          style = "purple";
          truncate_to_repo = true;
          truncation_length = 0;
          truncation_symbol = "repo: ";
        };
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        fennel.symbol = " ";
        fossil_branch.symbol = " ";
        git_branch.symbol = " ";
        golang.symbol = " ";
        guix_shell.symbol = " ";
        haskell.symbol = " ";
        haxe.symbol = " ";
        hg_branch.symbol = " ";
        hostname = {
          disabled = false;
          format = "[$hostname]($style) in ";
          ssh_only = false;
          ssh_symbol = " ";
          style = "bold dimmed red";
        };
        java.symbol = " ";
        julia.symbol = " ";
        kotlin.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = "󰍛 ";
        meson.symbol = "󰔷 ";
        nim.symbol = "󰆥 ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        ocaml.symbol = " ";
        package.symbol = "󰏗 ";
        perl.symbol = " ";
        php.symbol = " ";
        pijul_channel.symbol = " ";
        python.symbol = " ";
        rlang.symbol = "󰟔 ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        scan_timeout = 10;
        status = {
          disabled = false;
          map_symbol = true;
        };
        sudo.disabled = false;
        swift.symbol = " ";
        username = {
          format = " [$user]($style)@";
          show_always = true;
          style_root = "bold red";
          style_user = "bold red";
        };
        zig.symbol = " ";
      };
    };
  };

  # General nix settings
  nix.package = pkgs.lix;

  system.stateVersion = "24.05";
}
