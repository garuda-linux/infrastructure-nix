{ pkgs
, sources
, garuda-lib
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
      net.tls.certificateKeyFile: /run/credentials/mongodb.service/mongodb.pem
      net.tls.CAFile: /run/credentials/mongodb.service/ca.crt
      net.tls.allowConnectionsWithoutCertificates: true
    '';
    quiet = true;
    initialRootPassword = "yupHasAlreadyBeenChanged";
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

