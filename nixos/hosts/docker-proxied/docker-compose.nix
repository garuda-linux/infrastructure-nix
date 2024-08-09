# Auto-generated using compose2nix v0.2.2-pre.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."librey" = {
    image = "ghcr.io/ahwxorg/librey:latest";
    environment = {
      "CONFIG_CACHE_TIME" = "20";
      "CONFIG_DISABLE_BITTORRENT_SEARCH" = "false";
      "CONFIG_GOOGLE_DOMAIN" = "com";
      "CONFIG_HIDDEN_SERVICE_SEARCH" = "true";
      "CONFIG_INSTANCE_FALLBACK" = "true";
      "CONFIG_INVIDIOUS_INSTANCE" = "https://invidious.snopyta.org";
      "CONFIG_LANGUAGE" = "en";
      "CONFIG_NUMBER_OF_RESULTS" = "10";
      "CONFIG_RATE_LIMIT_COOLDOWN" = "25";
      "CONFIG_TEXT_SEARCH_ENGINE" = "google";
    };
    ports = [
      "8081:8080/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=librey"
      "--network=proxied_default"
    ];
  };
  systemd.services."docker-librey" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
  };
  virtualisation.oci-containers.containers."lingva" = {
    image = "thedaviddelta/lingva-translate:latest";
    environment = {
      "DARK_THEME" = "true";
      "DEFAULT_SOURCE_LANG" = "auto";
      "DEFAULT_TARGET_LANG" = "en";
      "HTTPS_PROXY" = "http://10.0.5.1:3128";
      "HTTP_PROXY" = "http://10.0.5.1:3128";
      "SITE_DOMAIN" = "lingva.garudalinux.org";
    };
    ports = [
      "3002:3000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=lingva"
      "--network=proxied_default"
    ];
  };
  systemd.services."docker-lingva" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
  };
  virtualisation.oci-containers.containers."redlib" = {
    image = "quay.io/redlib/redlib:latest";
    environment = {
      "REDLIB_BANNER_" = "Garuda's Redlib";
      "REDLIB_DEFAULT_AUTOPLAY_VIDEOS" = "true";
      "REDLIB_DEFAULT_BLUR_NSFW" = "true";
      "REDLIB_DEFAULT_COMMENT_SORT" = "confidence";
      "REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION" = "false";
      "REDLIB_DEFAULT_FIXED_NAVBAR" = "true";
      "REDLIB_DEFAULT_FRONT_PAGE" = "popular";
      "REDLIB_DEFAULT_HIDE_AWARDS" = "true";
      "REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION=" = "true";
      "REDLIB_DEFAULT_HIDE_SCORE" = "false";
      "REDLIB_DEFAULT_LAYOUT" = "card";
      "REDLIB_DEFAULT_POST_SORT" = "hot";
      "REDLIB_DEFAULT_SHOW_NSFW" = "false";
      "REDLIB_DEFAULT_THEME" = "dracula";
      "REDLIB_DEFAULT_USE_HLS" = "true";
      "REDLIB_DEFAULT_WIDE" = "false";
      "REDLIB_PUSHSHIFT_FRONTEND" = "undelete.pullpush.io";
      "REDLIB_ROBOTS_DISABLE_INDEXING" = "true";
      "REDLIB_SFW_ONLY" = "false";
    };
    ports = [
      "8082:8080/tcp"
    ];
    user = "nobody";
    log-driver = "journald";
    extraOptions = [
      "--cap-drop=ALL"
      "--health-cmd=[\"wget\",\"--spider\",\"-q\",\"--tries=1\",\"http://localhost:8082/settings\"]"
      "--health-interval=5m0s"
      "--health-timeout=3s"
      "--network-alias=redlib"
      "--network=proxied_default"
      "--security-opt=no-new-privileges:true"
    ];
  };
  systemd.services."docker-redlib" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
  };
  virtualisation.oci-containers.containers."searx" = {
    image = "searxng/searxng:latest";
    environment = {
      "BASE_URL" = "https://searx.garudalinux.org/";
      "BIND_ADDRESS" = "0.0.0.0:8080";
      "HTTPS_PROXY" = "http://10.0.5.1:3128";
      "HTTP_PROXY" = "http://10.0.5.1:3128";
      "INSTANCE_NAME" = "Garuda's SearxNG";
      "NO_PROXY" = "*.garudalinux.org";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/proxied/searxng:/etc/searxng:rw"
    ];
    ports = [
      "8080:8080/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--cap-add=CHOWN"
      "--cap-add=DAC_OVERRIDE"
      "--cap-add=SETGID"
      "--cap-add=SETUID"
      "--cap-drop=ALL"
      "--network-alias=searx"
      "--network=proxied_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/proxied.env"
    ];
  };
  systemd.services."docker-searx" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/proxied/searxng"
    ];
  };
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "--cleanup" "searx" "lingva" "whoogle" "librey" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=watchtower"
      "--network=proxied_default"
    ];
  };
  systemd.services."docker-watchtower" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."whoogle" = {
    image = "benbusby/whoogle-search:latest";
    environment = {
      "WHOOGLE_AUTOCOMPLETE" = "1";
      "WHOOGLE_CONFIG_LANGUAGE" = "lang_en";
      "WHOOGLE_CONFIG_NEW_TAB" = "1";
      "WHOOGLE_CONFIG_SEARCH_LANGUAGE" = "lang_en";
      "WHOOGLE_CONFIG_STYLE" = ":root {--whoogle-logo: #4c4f69;--whoogle-page-bg: #eff1f5;--whoogle-element-bg: #bcc0cc;--whoogle-text: #4c4f69;--whoogle-contrast-text: #5c5f77;--whoogle-secondary-text: #6c6f85;
  --whoogle-result-bg: #ccd0da;--whoogle-result-title: #7287fd;--whoogle-result-url: #dc8a78;--whoogle-result-visited: #e64553;--whoogle-dark-logo: #cdd6f4;
  --whoogle-dark-page-bg: #1e1e2e;--whoogle-dark-element-bg: #45475a;--whoogle-dark-text: #cdd6f4;--whoogle-dark-contrast-text: #bac2de;--whoogle-dark-secondary-text: #a6adc8;
  --whoogle-dark-result-bg: #313244;--whoogle-dark-result-title: #b4befe;--whoogle-dark-result-url: #f5e0dc;--whoogle-dark-result-visited: #eba0ac;}
  #whoogle-w {fill: #89b4fa;} #whoogle-h {fill: #f38ba8;}#whoogle-o-1 {fill: #f9e2af;}#whoogle-o-2 {fill: #89b4fa;}#whoogle-g {fill: #a6e3a1;}#whoogle-l {fill: #f38ba8;}
  #whoogle-e {fill: #f9e2af;}
  ";
      "WHOOGLE_CONFIG_THEME" = "dark";
      "WHOOGLE_CONFIG_URL" = "https://search.garudalinux.org";
      "WHOOGLE_CONFIG_VIEW_IMAGE" = "1";
      "WHOOGLE_RESULTS_PER_PAGE" = "15";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/proxied/whoogle:/config:rw"
    ];
    ports = [
      "5000:5000/tcp"
    ];
    user = "whoogle";
    log-driver = "journald";
    extraOptions = [
      "--cap-drop=ALL"
      "--network-alias=whoogle"
      "--network=proxied_default"
      "--security-opt=no-new-privileges"
    ];
  };
  systemd.services."docker-whoogle" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-proxied_default.service"
    ];
    requires = [
      "docker-network-proxied_default.service"
    ];
    partOf = [
      "docker-compose-proxied-root.target"
    ];
    wantedBy = [
      "docker-compose-proxied-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/proxied/whoogle"
    ];
  };

  # Networks
  systemd.services."docker-network-proxied_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f proxied_default";
    };
    script = ''
      docker network inspect proxied_default || docker network create proxied_default
    '';
    partOf = [ "docker-compose-proxied-root.target" ];
    wantedBy = [ "docker-compose-proxied-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-proxied-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
