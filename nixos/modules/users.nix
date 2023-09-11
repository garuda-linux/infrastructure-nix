{ config
, garuda-lib
, keys
, lib
, pkgs
, ...
}: {
  # Generate password files with 
  # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt' > /path/to/passwordfile 
  # and add them to infra-nix-secrets repo
  users = {
    # All users are immuntable; if a password is required it needs to be set via passwordFile
    mutableUsers = false;
    # Define our users
    users.ansible = {
      extraGroups = [ "wheel" ];
      home = "/home/ansible";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.nico keys.tne ];
      uid = lib.mkIf garuda-lib.unifiedUID 1000;
    };
    # Garuda admins - god mode
    users.nico = {
      extraGroups = [ "wheel" "docker" "chaotic_op" ];
      home = "/home/nico";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.nico ];
      passwordFile = "/var/garuda/secrets/pass/nico";
      uid = lib.mkIf garuda-lib.unifiedUID 1001;
    };
    users.sgs = {
      extraGroups = [ "wheel" ];
      home = "/home/sgs";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxBY8TX0iEQkf3Bym+3XVlrk8OLOwHOrj7Uy+WxjncOkkutyZ1WsY9liF4j9yjptyQG7Lx8OM8q44NE6+Rk1OXJXMF7CZ4Jq/WvMVnh2zKyNnF8wHBcspsAdG90wCxo6OmNpnY/rRRlNwwnore7raF2PrERtSlsEvLsUgvspYQ8cnLwerJP43QeETlpE1oR0FrbXWQet0I63Ky6UDEp07x0yee21VHnAG74rjGeFGwJBmCPSxnfGVNhCaR0zyu9+hh222liBrlilYm8nqLlsYGZCXiVdOxXJbBy89EVpHds7Lutf+TAYwsPGZf7U4k+g2Jx8N0JHXyzVZa0zS+I48+tqBBflEOqU9oEfGuz4cU/qWys5soLcRX2p9td+RF3OEdBKlTW4UYsINJUri6QSEUrsGaXqQZy8Ds2FBdUpb4pmFVlo9+4qRouiI80a5xVa7a1E5eS5xK5BzWH4fNg5SqtT5L9i2i1ocZp7FA0oa+ixnXNiC1umPZaY/9s+5fh1s= sgs-linux@shell.sf.net"
      ];
      passwordFile = "/var/garuda/secrets/pass/sgs";
      uid = lib.mkIf garuda-lib.unifiedUID 1002;
    };
    users.tne = {
      extraGroups = [ "wheel" "docker" "chaotic_op" ];
      home = "/home/tne";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ keys.tne ];
      passwordFile = "/var/garuda/secrets/pass/tne";
      uid = lib.mkIf garuda-lib.unifiedUID 1003;
    };

    # Garuda maintainers - limited access to buildiso
    users.frank = {
      home = "/home/frank";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf config.services.garuda-iso.enable [ keys.frank ];
      shell = lib.mkIf (!config.services.garuda-iso.enable) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1007;
    };

    # Chaotic-AUR maintainers - limited access to chaotic-aur builders
    users.technetium = {
      extraGroups = lib.mkIf config.services.chaotic.enable [ "chaotic_op" ];
      home = "/home/technetium";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf config.services.chaotic.enable [ keys.technetium1 ];
      shell = lib.mkIf (!config.services.chaotic.enable) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1004;
    };
    users.alexjp = {
      extraGroups = lib.mkIf config.services.chaotic.enable [ "chaotic_op" ];
      home = "/home/alexjp";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf config.services.chaotic.enable [ keys.alexjp ];
      shell = lib.mkIf (!config.services.chaotic.enable) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1005;
    };
    users.xiota = {
      extraGroups = lib.mkIf config.services.chaotic.enable [ "chaotic_op" ];
      home = "/home/xiota";
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = lib.mkIf config.services.chaotic.enable [ keys.xiota ];
      shell = lib.mkIf (!config.services.chaotic.enable) "${pkgs.util-linux}/bin/nologin";
      uid = lib.mkIf garuda-lib.unifiedUID 1006;
    };
  };

  # Sudo configuration
  security.sudo.extraRules = [{
    users = [ "ansible" "tne" "nico" "sgs" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
