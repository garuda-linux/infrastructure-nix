{ pkgs, ... }:
let
  initscript = pkgs.writeShellScript "motdscript" ''
    ${pkgs.fancy-motd}/bin/motd

    # Own additions
    echo -e ""
    echo -e "                 Please behave well and have fun! 🦅               "
    echo -e "         In case of issues or questions contact Nico or TNE.       "

    # Nico wants to actually have a look at it before tmux kills it
    if [[ $USER = nico ]]; then
      sleep 4
    fi
  '';
in {
  # Add fancy MOTD to shell logins
  environment.interactiveShellInit = "${initscript}";
}
