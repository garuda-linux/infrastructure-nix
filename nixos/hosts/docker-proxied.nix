{ pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../modules
    ./docker-proxied/docker-compose.nix
  ];

  # Let Docker use squid as outgoig proxy
  # Fails to pull images if *.docker.io is not excluded from proxy
  systemd.services.docker = {
    environment = {
      HTTPS_PROXY = "http://10.0.5.1:3128";
      HTTP_PROXY = "http://10.0.5.1:3128";
      NO_PROXY = "localhost,127.0.0.1,*.docker.io,ghcr.io";
    };
  };

  # This is another workaround for the Docker not restarting the container
  systemd.services.check-whoogle = {
    description = "Check whether Whoogle crashed again";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        if ! ${pkgs.curl}/bin/curl -m 10 -s http://localhost:5000/ > /dev/null; then
          ${pkgs.docker}/bin/docker restart whoogle
        fi
      '';
      Restart = "on-failure";
      RestartSec = "30";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.check-whoogle = {
    description = "Check whether Whoogle crashed again";
    timerConfig.OnCalendar = [ "*:0/15" ];
    wantedBy = [ "timers.target" ];
  };

  system.stateVersion = "23.05";
}
