{ keys_nico, keys_tne, ... }:
{
  users.users.ansible = {
    isNormalUser = true;
    home = "/home/ansible";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys_nico keys_tne ];
  };

  users.users.tne = {
    isNormalUser = true;
    home = "/home/tne";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys_tne ];
  };
  users.users.nico = {
    isNormalUser = true;
    home = "/home/nico";
    extraGroups = [ "wheel" "docker" ];
    openssh.authorizedKeys.keyFiles = [ keys_nico ];
  };

  security.sudo.extraRules = [{
    users = [ "ansible" "tne" "nico" ];
    commands = [{
      command = "ALL";
      options = [ "NOPASSWD" ];
    }];
  }];
}
