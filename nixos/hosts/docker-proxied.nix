{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../modules/garuda.nix
  ];

  # This container runs proxied docker containers
  services.docker-compose-runner.proxied = {
    envfile = garuda-lib.secrets.docker-compose.proxied;
    source = ../../docker-compose/proxied;
  };

  # Let Docker use squid as outgoig proxy
  # Fails to pull images if *.docker.io is not excluded from proxy
  systemd.services.docker = {
    environment = {
      HTTPS_PROXY = "http://10.0.5.1:3128";
      HTTP_PROXY = "http://10.0.5.1:3128";
      NO_PROXY = "localhost,127.0.0.1,*.docker.io";
    };
  };

  system.stateVersion = "23.05";
}
