{
  lib,
  pkgs,
  sources,
  ...
}:
let
  # Simple wrapper to dispatch SSH commands to NixOS
  ci-trigger = pkgs.writeShellScriptBin "ci-trigger" ''
    echo $SSH_ORIGINAL_COMMAND
    _FLAVOUR=$(echo "$SSH_ORIGINAL_COMMAND" | cut -d' ' -f2)
    _KERNEL=$(echo "$SSH_ORIGINAL_COMMAND" | cut -d' ' -f3)

    case "$SSH_ORIGINAL_COMMAND" in
      "ci-trigger buildall")
        echo "Ensuring container and garuda-tools are up-to-date.."
        docker exec buildiso pacman -Syu --noconfirm || exit 1
        echo "Building all ISO Garuda currently offers.."
        docker exec buildiso buildall || exit 1
        ;;
      "ci-trigger "* )
        echo "Ensuring container and garuda-tools are up-to-date.."
        docker exec buildiso pacman -Syu --noconfirm || exit 2
        echo "Building $_FLAVOUR.."
        docker exec buildiso buildiso -i || exit 2
        [[ $_KERNEL != "" ]] && (docker exec buildiso buildiso -p "$_FLAVOUR" -k "$_KERNEL" || exit 3)
        docker exec buildiso buildiso -p "$_FLAVOUR" || exit 3
        ;;
      *)
        echo "Access only allowed for building purposes!"
        exit 4
    esac
  '';
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  # Lets build Garuda ISO here, serving is done via
  # Temeraire already
  services = {
    garuda-iso.enable = true;
    nginx.enable = lib.mkForce false;
    rsyncd.enable = lib.mkForce false;
  };

  # Create a locked down user for GitLab CI who can only access our wrapper
  users.users.gitlab = {
    extraGroups = [ "docker" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "restrict,pty,command=\"${ci-trigger}/bin/ci-trigger\"  ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p"
    ];
  };

  # Let maintainers use buildiso (which is a wrapper around the Docker container)
  # without having to enter a password - our devshell should work just like that
  security.sudo.extraRules = [
    {
      users = [ "frank" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/buildiso";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  users.users.frank.extraGroups = [ "docker" ];

  system.stateVersion = "25.05";
}
