{ garuda-lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

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
      NO_PROXY = "localhost,127.0.0.1,*.docker.io,ghcr.io";
    };
  };

  # This one is set manually as service because it needs restart: always
  # (which the docker-compose-runner overwrites) - update: this does not help either.
  virtualisation.oci-containers = {
    backend = "docker";
    containers.whoogle = {
      environment = {
        WHOOGLE_AUTOCOMPLETE = "1";
        WHOOGLE_CONFIG_LANGUAGE = "lang_en";
        WHOOGLE_CONFIG_NEW_TAB = "1";
        WHOOGLE_CONFIG_SEARCH_LANGUAGE = "lang_en";
        WHOOGLE_CONFIG_STYLE = ":root {--whoogle-logo: #4c4f69;--whoogle-page-bg: #eff1f5;--whoogle-element-bg: #bcc0cc;--whoogle-text: #4c4f69;--whoogle-contrast-text: #5c5f77;--whoogle-secondary-text: #6c6f85;
            --whoogle-result-bg: #ccd0da;--whoogle-result-title: #7287fd;--whoogle-result-url: #dc8a78;--whoogle-result-visited: #e64553;--whoogle-dark-logo: #cdd6f4;
            --whoogle-dark-page-bg: #1e1e2e;--whoogle-dark-element-bg: #45475a;--whoogle-dark-text: #cdd6f4;--whoogle-dark-contrast-text: #bac2de;--whoogle-dark-secondary-text: #a6adc8;
            --whoogle-dark-result-bg: #313244;--whoogle-dark-result-title: #b4befe;--whoogle-dark-result-url: #f5e0dc;--whoogle-dark-result-visited: #eba0ac;}
            #whoogle-w {fill: #89b4fa;} #whoogle-h {fill: #f38ba8;}#whoogle-o-1 {fill: #f9e2af;}#whoogle-o-2 {fill: #89b4fa;}#whoogle-g {fill: #a6e3a1;}#whoogle-l {fill: #f38ba8;}
            #whoogle-e {fill: #f9e2af;}";
        WHOOGLE_CONFIG_THEME = "dark";
        WHOOGLE_CONFIG_URL = "https://search.garudalinux.org";
        WHOOGLE_CONFIG_VIEW_IMAGE = "1";
        WHOOGLE_RESULTS_PER_PAGE = "15";
      };
      extraOptions = [
        "--cap-drop=all"
        "--pids-limit=50"
        "--security-opt=no-new-privileges:true"
        "--tmpfs=/run/tor/:size=1M,uid=927,gid=927,mode=1700"
        "--tmpfs=/var/lib/tor/:size=10M,uid=927,gid=927,mode=1700"
      ];
      hostname = "whoogle";
      image = "benbusby/whoogle-search:latest";
      ports = [ "5000:5000" ];
      user = "whoogle";
      volumes = [ "/var/garuda/docker-compose-runner/proxied/whoogle:/config" ];
    };
  };

  # This is another workaround for the Docker not restarting the container
  systemd.services.check-whoogle = {
    description = "Check whether Whoogle crashed again";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        if ! curl -m 10 -s http://localhost:5000/ > /dev/null; then
          docker restart whoogle
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
