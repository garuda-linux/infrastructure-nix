{ pkgs
, sources
, garuda-lib
, ...
}:
{
  imports = sources.defaultModules ++ [ ../modules ];

  # Our MongoDB database
  services.mongodb = {
    bind_ip = "10.0.5.60";
    enable = true;
    enableAuth = true;
    extraConfig = ''
      net.tls.mode: requireTLS
      net.tls.certificateKeyFile: /run/credentials/mongodb.service/mongodb.pem
      net.tls.CAFile: /run/credentials/mongodb.service/ca.crt
      net.tls.allowConnectionsWithoutCertificates: true
    '';
    initialRootPassword = "yupHasAlreadyBeenChanged";
    # Prevent hours of waiting for mongodb to be compiled
    package = pkgs.mongodb-ce;
    quiet = true;
  };

  systemd.services.mongodb = {
    serviceConfig = {
      LoadCredential = [ "ca.crt:${garuda-lib.secrets.mongodb.CA}" "mongodb.pem:${garuda-lib.secrets.mongodb.pem}" ];
    };
  };

  # MongoDB port is being forwarded to this container
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  # Local management
  environment.systemPackages = [ pkgs.mongosh ];

  system.stateVersion = "24.05";
}

