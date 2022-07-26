{ ... }:
let
  keys_nico = builtins.fetchurl "https://github.com/dr460nf1r3.keys";
  keys_tne = builtins.fetchurl "https://github.com/justtne.keys";
in {
  users.users.ansible = {
    isNormalUser = true;
    home = "/home/ansible";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ keys_nico keys_tne ];
  };

  users.users.tne = {
    isNormalUser = true;
    home = "/home/tne";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keyFiles = [ keys_tne ];
  };
  users.users.nico = {
    isNormalUser = true;
    home = "/home/nico";
    extraGroups = [ "wheel" ];
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
