{ keys, lib, config,  ... }:
{
  users.users.ansible = {
    isNormalUser = true;
    home = "/home/ansible";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ keys.nico keys.tne ];
  };

  users.users.tne = {
    isNormalUser = true;
    home = "/home/tne";
    extraGroups = [ "wheel" "docker" "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.tne ];
  };
  users.users.nico = {
    isNormalUser = true;
    home = "/home/nico";
    extraGroups = [ "wheel" "docker" "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.nico ];
  };

  users.users.technetium = lib.mkIf config.services.chaotic.enable {
    isNormalUser = true;
    home = "/home/technetium";
    extraGroups = [ "chaotic_op" ];
    openssh.authorizedKeys.keyFiles = [ keys.technetium1 keys.nico ];
  };

  security.sudo.extraRules = [{
    users = [ "ansible" "tne" "nico" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
