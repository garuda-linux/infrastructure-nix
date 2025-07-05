{
  config,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  # This container runs proxied docker containers
  garuda.services.compose-runner.docker-proxied = {
    envfile = config.sops.secrets."compose/docker-proxied".path;
    source = ../../../compose/docker-proxied;
  };

  # Let Docker use squid as outgoig proxy
  # Fails to pull images if *.docker.io is not excluded from proxy
  # systemd.services.docker = {
  #   environment = {
  #     HTTPS_PROXY = "http://10.0.5.1:3128";
  #     HTTP_PROXY = "http://10.0.5.1:3128";
  #     NO_PROXY = "localhost,127.0.0.1,*.docker.io,ghcr.io";
  #   };
  # };

  sops.secrets."compose/docker-proxied" = { };

  system.stateVersion = "25.05";
}
