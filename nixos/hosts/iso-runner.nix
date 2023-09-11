{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Lets build Garuda ISO here, serving is done via
  # Temeraire already 
  services = {
    garuda-iso.enable = true;
    nginx.enable = lib.mkForce false;
    rsyncd.enable = lib.mkForce false;
  };

  # Let maintainers use buildiso (which is a wrapper around the Docker container)
  # without having to enter a password - our devshell should work just like that
  security.sudo.extraRules = [{
    users = [ "frank" ];
    commands = [{
      command = "/run/current-system/sw/bin/buildiso";
      options = [ "NOPASSWD" ];
    }];
  }];

  system.stateVersion = "23.05";
}
