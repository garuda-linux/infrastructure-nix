{
  config,
  garuda-lib,
  keys,
  lib,
  pkgs,
  ...
}:
{
  # Generate password files with
  # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt' > /path/to/hashedPasswordFile
  # and add them to infra-nix-secrets repo
  users = {
    # All users are immuntable; if a password is required it needs to be set via hashedPasswordFile
    mutableUsers = false;
    # Define our users
    users.ansible = {
      extraGroups = [ "wheel" ];
      home = "/home/ansible";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [
        keys.nico
        keys.tne
      ];
      uid = lib.mkIf garuda-lib.unifiedUID 1000;
    };

    # Garuda admins - god mode
    # ANCHOR: admins
    users.nico = {
      extraGroups = [
        "wheel"
        "docker"
        "chaotic_op"
      ];
      home = "/home/nico";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.nico ];
      hashedPasswordFile = config.sops.secrets."passwords/nico".path;
      uid = lib.mkIf garuda-lib.unifiedUID 1001;
    };
    users.sgs = {
      extraGroups = [ "wheel" ];
      home = "/home/sgs";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxBY8TX0iEQkf3Bym+3XVlrk8OLOwHOrj7Uy+WxjncOkkutyZ1WsY9liF4j9yjptyQG7Lx8OM8q44NE6+Rk1OXJXMF7CZ4Jq/WvMVnh2zKyNnF8wHBcspsAdG90wCxo6OmNpnY/rRRlNwwnore7raF2PrERtSlsEvLsUgvspYQ8cnLwerJP43QeETlpE1oR0FrbXWQet0I63Ky6UDEp07x0yee21VHnAG74rjGeFGwJBmCPSxnfGVNhCaR0zyu9+hh222liBrlilYm8nqLlsYGZCXiVdOxXJbBy89EVpHds7Lutf+TAYwsPGZf7U4k+g2Jx8N0JHXyzVZa0zS+I48+tqBBflEOqU9oEfGuz4cU/qWys5soLcRX2p9td+RF3OEdBKlTW4UYsINJUri6QSEUrsGaXqQZy8Ds2FBdUpb4pmFVlo9+4qRouiI80a5xVa7a1E5eS5xK5BzWH4fNg5SqtT5L9i2i1ocZp7FA0oa+ixnXNiC1umPZaY/9s+5fh1s= sgs-linux@shell.sf.net" # pragma: allowlist secret,
      ];
      hashedPasswordFile = config.sops.secrets."passwords/sgs".path;
      uid = lib.mkIf garuda-lib.unifiedUID 1002;
    };
    users.tne = {
      extraGroups = [
        "wheel"
        "docker"
        "chaotic_op"
      ];
      home = "/home/tne";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.tne ];
      hashedPasswordFile = config.sops.secrets."passwords/tne".path;
      uid = lib.mkIf garuda-lib.unifiedUID 1003;
    };
    # ANCHOR_END: admins
    # Garuda maintainers - limited access to buildiso
    # ANCHOR: maintainers
    users.frank = {
      home = "/home/frank";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf config.services.garuda-iso.enable [ keys.frank ];
      shell = lib.mkIf (!config.services.garuda-iso.enable) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1007;
    };
    # ANCHOR_END: maintainers
    # Chaotic-AUR maintainers - limited access to chaotic-aur builders
    # ANCHOR: chaotic-aur
    users.technetium = {
      extraGroups = lib.mkIf garuda-lib.chaoticUsers [ "chaotic_op" ];
      home = "/home/technetium";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf garuda-lib.chaoticUsers [ keys.technetium1 ];
      shell = lib.mkIf (!garuda-lib.chaoticUsers) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1004;
    };
    users.alexjp = {
      extraGroups = lib.mkIf garuda-lib.chaoticUsers [ "chaotic_op" ];
      home = "/home/alexjp";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf garuda-lib.chaoticUsers [ keys.alexjp ];
      shell = lib.mkIf (!garuda-lib.chaoticUsers) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1005;
    };
    users.xiota = {
      extraGroups = lib.mkIf garuda-lib.chaoticUsers [ "chaotic_op" ];
      home = "/home/xiota";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf garuda-lib.chaoticUsers [ keys.xiota ];
      shell = lib.mkIf (!garuda-lib.chaoticUsers) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1006;
    };
    # ANCHOR_END: chaotic-aur
  };

  # Sudo configuration
  security.sudo.extraRules = [
    {
      users = [
        "ansible"
        "tne"
        "nico"
        "sgs"
      ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  sops.secrets = {
    "passwords/nico".neededForUsers = true;
    "passwords/tne".neededForUsers = true;
    "passwords/sgs".neededForUsers = true;
  };
}
