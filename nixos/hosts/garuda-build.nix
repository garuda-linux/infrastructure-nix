{ pkgs
, sources
, ...
}:
let
  wrapperScript = pkgs.writeScriptBin "chaotic-restart" ''
    systemctl restart docker-compose-chaotic-v4-builder-root.target 
  '';
in
{
  imports = [
    "${sources.chaotic-portable-builder}/nix/nixos.nix"
    ../modules
    # ./garuda-build/docker-compose.nix
    ./garuda-build/hardware-configuration.nix
  ];

  # Base configuration
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "216.158.66.108";
    prefixLength = 24;
  }];
  networking.hostName = "garuda-build";
  networking.defaultGateway = "216.158.66.97";

  # At least try to prevent the insane spam of login attempts
  services.openssh.ports = [ 1022 ];

  # Lock down chaotic-op group to SCP in landing zone
  services.openssh.extraConfig = ''
    Match Group chaotic-op
      AllowAgentForwarding no
      AllowTCPForwarding yes
      ForceCommand internal-sftp
      PermitOpen 127.0.0.1:6379
      PermitTunnel no
      X11Forwarding no
  '';

  # Enable the user accounts of chaotic maintainers
  garuda-lib.chaoticUsers = true;

  # Allow controlling infra 4.0's containers without root
  environment.systemPackages = [ wrapperScript ];
  security.sudo.extraRules = [
    { users = [ "xiota" ]; commands = [{ command = "${wrapperScript}/bin/chaotic-restart"; options = [ "NOPASSWD" ]; }]; }
  ];

  system.stateVersion = "22.05";
}
