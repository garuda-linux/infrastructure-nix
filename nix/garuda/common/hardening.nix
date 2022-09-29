{ config, ... }:

{
  # Disable coredumps
  systemd.coredump.enable = false;

  # Of course no password authentication on sshd
  services.openssh.passwordAuthentication = false;

  # The hardening profile enables Apparmor by default
  security.apparmor.enable = false;

  # Timeout TTY after 1 hour
  programs.bash.interactiveShellInit =
    "if [[ $(tty) =~ /dev\\/tty[1-6] ]]; then TMOUT=3600; fi";

  security.lockKernelModules = false;
}
