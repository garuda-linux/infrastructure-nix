{ keys, ... }:
{
  users.users.ansible = {
    isNormalUser = true;
    home = "/home/ansible";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys.nico keys.tne ];
  };

  users.users.tne = {
    isNormalUser = true;
    home = "/home/tne";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys.tne ];
  };
  users.users.nico = {
    isNormalUser = true;
    home = "/home/nico";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys.nico ];
  };

  security.sudo.extraRules = [{
    users = [ "ansible" "tne" "nico" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
