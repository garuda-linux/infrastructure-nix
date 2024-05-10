{ garuda-lib
, sources
, ...
}: {
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

  # Contains a builder container only
  services.docker-compose-runner.chaotic-v4 = {
    envfile = garuda-lib.secrets.docker-compose.chaotic-v4-builder;
    source = ../../docker-compose/chaotic-v4-builder;
  };

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

  system.stateVersion = "22.05";
}
