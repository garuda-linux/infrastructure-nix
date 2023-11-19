{ pkgs, ... }:
let
  initscript = pkgs.writeShellScript "motdscript" ''
    if [ $USER != nico ] && [ $USER != "package-deployer" ]; then
      ${pkgs.fancy-motd}/bin/motd

      # Own additions
      echo -e ""
      echo -e "                 Please behave well and have fun! 🦅               "
      echo -e "         In case of issues or questions contact Nico or TNE.       "
    fi
    HISTCONTROL=ignoreboth
  '';
in
{
  # Add fancy MOTD to shell logins
  environment.interactiveShellInit = "${initscript}";
}
