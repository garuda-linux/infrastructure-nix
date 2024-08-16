{ pkgs
, sources
, ...
}:
{
  imports = sources.defaultModules ++ [ ../modules ];

  # Our MongoDB database
  services.mongodb = {
    enable = true;
    bind_ip = "10.0.5.60";
    enableAuth = true;
    extraConfig = ''
      net.tls.mode: requireTLS
      net.tls.certificateKeyFile: /etc/ssl/mongodb/mongodb.pem
      net.tls.CAFile: /etc/ssl/mongodb/ca.crt
      net.tls.allowConnectionsWithoutCertificates: true
    '';
    quiet = true;
    initialRootPassword = "yupHasAlreadyBeenChanged";
  };

  # MongoDB port is being forwarded to this container
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  # Local management
  environment.systemPackages = [ pkgs.mongosh ];

  system.stateVersion = "24.05";
}

