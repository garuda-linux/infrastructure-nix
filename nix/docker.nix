{ garuda-lib
, lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Avoid running Netdata instances in containers
  services.garuda-monitoring.enable = lib.mkForce false;

  # This container is just for docker-compose stuff
  services.docker-compose-runner.all-in-one = {
    envfile = garuda-lib.secrets.docker-compose.all-in-one;
    source = ./docker-compose/all-in-one;
  };

  # MongoDB port is being forwarded to this container
  networking.firewall = { allowedTCPPorts = [ 27017 ]; };

  # # Cloudflared access to Meshcentral webinterface
  # services.garuda-cloudflared = {
  #   enable = true;
  #   ingress = {
  #     "mesh.garudalinux.net" = "http://127.0.0.1:80";
  #     "matrixadmin.garudalinux.net" = "http://esxi-web-two:8081";
  #     "opnsense.garudalinux.net" = { service = "https://192.168.1.1"; originRequest.noTLSVerify = true; };
  #   };
  #   tunnel-credentials =
  #     garuda-lib.secrets.cloudflare.cloudflared.esxi-web.cred;
  # };

  system.stateVersion = "23.05";
}
