{ pkgs
, sources
, ...
}:
let
  # Simple wrapper to dispatch SSH commands to NixOS
  chaotictrigger = pkgs.writeShellScriptBin "chaotictrigger" ''
    _PACKAGE=$(echo $SSH_ORIGINAL_COMMAND | cut -d' ' -f2)
    _BUILD_DIR=$(mktemp -d)

    case "$SSH_ORIGINAL_COMMAND" in
      "chaotictrigger routine")
        echo "Building a full routine.."
        chaotic -j 4 routine garuda || exit 1
        ;;
      "chaotictrigger "* )
        echo "Building $_PACKAGE in $_BUILD_DIR.."
        git clone https://gitlab.com/garuda-linux/pkgbuilds "$_BUILD_DIR"
        cd "$_BUILD_DIR"
        chaotic mkd "$_PACKAGE" || exit 2
        rm -rf "$_BUILD_DIR"
        ;;
      *)
        echo "Access only allowed for building purposes!"
        exit 666
    esac
  '';
in
{
  imports = sources.defaultModules ++ [ ../modules ];

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "garuda-repo";
  services.chaotic.host = "repo.garudalinux.org";
  services.chaotic.extraConfig = ''
    export CAUR_DEPLOY_LABEL="Maximus 🐉"
    export CAUR_LOWER_PKGS+=(chaotic-mirrorlist chaotic-keyring)
    export CAUR_PACKAGER="Garuda Builder <team@garudalinux.org>"
    export CAUR_SIGN_KEY=D6C9442437365605
    export CAUR_ROUTINES=/tmp/chaotic/routines
    export CAUR_SIGN_USER=root
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"

    export GIT_SSH_COMMAND="ssh -i /var/garuda/secrets/chaotic/interfere_ed25519"
    export HTTP_PROXY=http://10.0.5.1:3128/
    export HTTPS_PROXY=http://10.0.5.1:3128/
    export NO_PROXY=mirror.rackspace.com,cloudflaremirrors.com,github.com,downloads.sentry-cdn.com
  '';
  services.chaotic.db-name = "garuda";
  services.chaotic.routines = [ "hourly" ];
  services.chaotic.patches = [ ../services/chaotic/add-chaotic-repo.diff ];
  services.chaotic.useACMEHost = "garudalinux.org";

  # Allow systemd-nspawn to create subcgroups (for Chaotic-AUR builders)
  systemd.services.remount-sysfscgroup = {
    description = "Remount cgroup2 to allow systemd-nspawn to create subcgroups";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.mount}/bin/mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup
    '';
  };

  # Create locked down users for GitLab CI who can only access our wrapper
  users.users.gitlab = {
    isNormalUser = true;
    extraGroups = [ "chaotic_op" ];
    openssh.authorizedKeys.keys = [ "restrict,pty,command=\"${chaotictrigger}/bin/chaotictrigger\" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p" ];
  };
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "packaging" ];
    openssh.authorizedKeys.keys = [ "restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p" ];
  };
  users.groups.packaging = { };

  system.stateVersion = "23.05";
}
