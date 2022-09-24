{ config, ... }:

{
    systemd.coredump.enable = false;
    services.openssh.passwordAuthentication = false;
    security.apparmor.enable = false;
}
