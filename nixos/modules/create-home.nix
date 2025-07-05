{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.services.create-homedirs = lib.mkIf (!config.boot.isContainer) {
    enable = true;
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -e
      # Create home directory if necessary
      function create_home_if_empty {
          [ ! -d "$1" ] && "${pkgs.linux-pam}/bin/mkhomedir_helper" && echo "Created home directory for $2" || echo "Home directory for $2 already exists"
      }
      ${lib.strings.concatLines (
        lib.mapAttrsToList (name: user: ''
          create_home_if_empty "${user.home}" "${name}"
        '') (lib.attrsets.filterAttrs (_name: user: user.isNormalUser) config.users.users)
      )}
    '';
  };
}
