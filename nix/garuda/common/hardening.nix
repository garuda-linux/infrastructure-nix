{ config, ... }:

{
  # Disable coredumps
  systemd.coredump.enable = false;

  # Disable root login & password authentication on sshd
  services.openssh = {
    passwordAuthentication = false;
    permitRootLogin = "no";
  };

  # The hardening profile enables Apparmor by default, we don't want this to happen
  security.apparmor.enable = false;

  # Timeout TTY after 1 hour
  programs.bash.interactiveShellInit =
    "if [[ $(tty) =~ /dev\\/tty[1-6] ]]; then TMOUT=3600; fi";

  # Don't lock kernel modules, this is also enabled by the hardening profile by default
  security.lockKernelModules = false;

  # Disable root user login
  users.users.root.hashedPassword = "*";
}
