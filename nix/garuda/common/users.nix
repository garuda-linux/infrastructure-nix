{ config
, keys
, lib
, ...
}: {
  # All users are immuntable; if a password is required it needs to be set via passwordFile
  users.mutableUsers = false;

  # Ansible user - generate password files with 
  # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt' > /path/to/passwordfile 
  # and add them to infra-nix-secrets repo
  users.users.ansible = {
    extraGroups = [ "wheel" ];
    home = "/home/ansible";
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ keys.nico keys.tne ];
  };
  # Garuda Admins
  users.users.tne = {
    extraGroups = [ "wheel" "docker" "chaotic_op" ];
    home = "/home/tne";
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ keys.tne ];
    passwordFile = "/var/garuda/secrets/pass/tne";
  };
  users.users.nico = {
    extraGroups = [ "wheel" "docker" "chaotic_op" ];
    home = "/home/nico";
    isNormalUser = true;
    openssh.authorizedKeys.keyFiles = [ keys.nico ];
    passwordFile = "/var/garuda/secrets/pass/nico";
  };
  users.users.sgs = {
    extraGroups = [ "wheel" ];
    home = "/home/sgs";
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxBY8TX0iEQkf3Bym+3XVlrk8OLOwHOrj7Uy+WxjncOkkutyZ1WsY9liF4j9yjptyQG7Lx8OM8q44NE6+Rk1OXJXMF7CZ4Jq/WvMVnh2zKyNnF8wHBcspsAdG90wCxo6OmNpnY/rRRlNwwnore7raF2PrERtSlsEvLsUgvspYQ8cnLwerJP43QeETlpE1oR0FrbXWQet0I63Ky6UDEp07x0yee21VHnAG74rjGeFGwJBmCPSxnfGVNhCaR0zyu9+hh222liBrlilYm8nqLlsYGZCXiVdOxXJbBy89EVpHds7Lutf+TAYwsPGZf7U4k+g2Jx8N0JHXyzVZa0zS+I48+tqBBflEOqU9oEfGuz4cU/qWys5soLcRX2p9td+RF3OEdBKlTW4UYsINJUri6QSEUrsGaXqQZy8Ds2FBdUpb4pmFVlo9+4qRouiI80a5xVa7a1E5eS5xK5BzWH4fNg5SqtT5L9i2i1ocZp7FA0oa+ixnXNiC1umPZaY/9s+5fh1s= sgs-linux@shell.sf.net"
    ];
    passwordFile = "/var/garuda/secrets/pass/sgs";
  };

  # Chaotic-AUR maintainers
  users.users.technetium = lib.mkIf config.services.chaotic.enable {
    isNormalUser = true;
    home = "/home/technetium";
    extraGroups = [ "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.technetium1 ];
  };
  users.users.alexjp = lib.mkIf config.services.chaotic.enable {
    isNormalUser = true;
    home = "/home/alexjp";
    extraGroups = [ "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.alexjp ];
  };
  users.users.xiota = lib.mkIf config.services.chaotic.enable {
    isNormalUser = true;
    home = "/home/xiota";
    extraGroups = [ "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.xiota ];
  };

  # Sudo configuration
  security.sudo.extraRules = [{
    users = [ "ansible" "tne" "nico" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
