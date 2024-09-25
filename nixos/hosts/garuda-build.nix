{ pkgs
, sources
, ...
}:
let
  wrapperScript = pkgs.writeScriptBin "chaotic-restart" ''
    cd /var/garuda/docker-compose-runner/chaotic-v4-builder/
    docker compose down
    docker compose up -d
  '';
in
{
  imports = [
    ../modules
    ./garuda-build/hardware-configuration.nix
    "${sources.chaotic-portable-builder}/nix/nixos.nix"
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

  system.stateVersion = "22.05";
}
