_: {
  services.openssh.extraConfig = ''
    Match Group iso-deployer
      AllowTCPForwarding no
      AllowAgentForwarding no
      X11Forwarding no
      PermitTunnel no
      ForceCommand internal-sftp
  '';

  users.users.iso-deployer = {
    isNormalUser = true;
    extraGroups = [ "iso-deployer" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIABXZGcKgjRcVWAcNGCyjd93oOPR3D4JKJkjocwayj4G" # pragma: allowlist secret
    ];
  };
  users.groups.iso-deployer = { };
}
