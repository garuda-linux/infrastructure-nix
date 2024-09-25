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
  virtualisation.oci-containers.containers."bitwarden" = {
    image = "vaultwarden/server:1.32.0";
    environment = {
      "DOMAIN" = "https://bitwarden.garudalinux.org";
      "SIGNUPS_ALLOWED" = "true";
      "SMTP_FROM" = "noreply@garudalinux.org";
      "SMTP_HOST" = "mail.garudalinux.org";
      "SMTP_PORT" = "587";
      "SMTP_SSL" = "false";
      "SMTP_USERNAME" = "noreply@garudalinux.org";
      "WEBSOCKET_ENABLED" = "true";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/bitwarden:/data:rw"
    ];
    ports = [
      "8081:80/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=bitwarden"
      "--network=all-in-one_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/all-in-one.env"
    ];
  };
  systemd.services."docker-bitwarden" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/bitwarden"
    ];
  };
  virtualisation.oci-containers.containers."element_web" = {
    image = "vectorim/element-web:v1.11.73";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/element/config.json:/app/config.json:rw"
    ];
    ports = [
      "8084:80/tcp"
    ];
    dependsOn = [
      "matrix"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=matrix_web"
      "--network=all-in-one_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/all-in-one.env"
    ];
  };
  systemd.services."docker-element_web" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/element/config.json"
    ];
  };
  virtualisation.oci-containers.containers."homer" = {
    image = "b4bz/homer:v24.05.1";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/startpage:/www/assets:rw"
    ];
    ports = [
      "8083:8080/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=homer"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-homer" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/startpage"
    ];
  };
  virtualisation.oci-containers.containers."lemmy_lcs" = {
    image = "nowsci/lcs:20240801065204";
    environment = {
      "COMMUNITY_COUNT" = "50";
      "COMMUNITY_SORT_METHODS" = ''[ "TopAll", "TopDay" ]'';
      "COMMUNITY_TYPE" = "All";
      "LOCAL_URL" = "https://lemmy.garudalinux.org";
      "MINUTES_BETWEEN_RUNS" = "240";
      "NSFW" = "false";
      "POST_COUNT" = "50";
      "REMOTE_INSTANCES" = ''[ "beehaw.org", "lemmy.world", "lemmy.ml", "sh.itjust.works", "lemmy.one" ]'';
      "SECONDS_AFTER_COMMUNITY_ADD" = "17";
    };
    log-driver = "journald";
    extraOptions = [
      "--network-alias=lemmy_seeder"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-lemmy_lcs" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
  };
  virtualisation.oci-containers.containers."matrix" = {
    image = "matrixdotorg/synapse:v1.112.0";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/matrix:/data:rw"
    ];
    ports = [
      "8008:8008/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=matrix"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-matrix" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/matrix"
    ];
  };
  virtualisation.oci-containers.containers."matrix_admin" = {
    image = "awesometechnologies/synapse-admin:latest";
    ports = [
      "8085:80/tcp"
    ];
    dependsOn = [
      "matrix"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=matrix_admin"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-matrix_admin" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
  };
  virtualisation.oci-containers.containers."matterbridge" = {
    image = "42wim/matterbridge:1.26";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/matterbridge/matterbridge.toml:/etc/matterbridge/matterbridge.toml:ro"
    ];
    dependsOn = [
      "matrix"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=matterbridge"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-matterbridge" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/matterbridge/matterbridge.toml"
    ];
  };
  virtualisation.oci-containers.containers."mautrix-telegram" = {
    image = "dock.mau.dev/mautrix/telegram";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/mautrix-telegram:/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--health-cmd=! (grep -q 'System clock is wrong, set time offset to' /tmp/debug.log && rm /tmp/debug.log && kill -SIGINT 1)"
      "--health-interval=1m0s"
      "--health-timeout=10s"
      "--network-alias=mautrix-telegram"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-mautrix-telegram" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/matrix/mautrix-telegram"
    ];
  };
  virtualisation.oci-containers.containers."mongodb" = {
    image = "mongo:7.0.12";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/mongo:/data/db:rw"
    ];
    ports = [
      "27017:27017/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=mongodb"
      "--network=all-in-one_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/all-in-one.env"
    ];
  };
  systemd.services."docker-mongodb" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/mongo"
    ];
  };
  virtualisation.oci-containers.containers."nextcloud-aio-mastercontainer" = {
    image = "nextcloud/all-in-one:latest";
    environment = {
      "APACHE_IP_BINDING" = "10.0.5.100";
      "APACHE_PORT" = "11000";
    };
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:ro"
      "nextcloud_aio_mastercontainer:/mnt/docker-aio-config:rw"
    ];
    ports = [
      "8080:8080/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=nextcloud-aio-mastercontainer"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-nextcloud-aio-mastercontainer" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
      "docker-volume-nextcloud_aio_mastercontainer.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
      "docker-volume-nextcloud_aio_mastercontainer.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."privatebin" = {
    image = "privatebin/nginx-fpm-alpine:1.7.4";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/configs/privatebin.cfg.php:/srv/cfg/conf.php:rw"
      "/var/garuda/docker-compose-runner/all-in-one/privatebin:/srv/data:rw"
    ];
    ports = [
      "8082:8080/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=privatebin"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-privatebin" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/configs/privatebin.cfg.php"
      "/var/garuda/docker-compose-runner/all-in-one/privatebin"
    ];
  };
  virtualisation.oci-containers.containers."syncserver" = {
    image = "crazymax/firefox-syncserver:edge";
    environment = {
      "FF_SYNCSERVER_ACCESSLOG" = "true";
      "FF_SYNCSERVER_FORCE_WSGI_ENVIRON" = "true";
      "FF_SYNCSERVER_FORWARDED_ALLOW_IPS" = "*";
      "FF_SYNCSERVER_PUBLIC_URL" = "https://ffsync.garudalinux.org";
      "FF_SYNCSERVER_SQLURI" = "sqlite:////data/syncserver.db";
      "TZ" = "Europe/Berlin";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/syncserver:/data:rw"
    ];
    ports = [
      "5001:5000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=syncserver"
      "--network=all-in-one_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/all-in-one.env"
    ];
  };
  systemd.services."docker-syncserver" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/syncserver"
    ];
  };
  virtualisation.oci-containers.containers."thelounge" = {
    image = "thelounge/thelounge:4.4.3";
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/thelounge:/var/opt/thelounge:rw"
    ];
    ports = [
      "9000:9000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=thelounge"
      "--network=all-in-one_default"
    ];
  };
  systemd.services."docker-thelounge" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/thelounge"
    ];
  };
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:1.7.1";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "--cleanup" "matrix_web" "matrix_admin" "wikijs" "mongodb" "homer" "privatebin" "bitwarden" "thelounge" "syncserver" "nextcloud_app" "lemmy_seeder" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=watchtower"
      "--network=all-in-one_default"
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
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."wikijs" = {
    image = "requarks/wiki:2.5";
    environment = {
      "DB_HOST" = "10.0.5.50";
      "DB_NAME" = "wikijs";
      "DB_PORT" = "5432";
      "DB_TYPE" = "postgres";
      "DB_USER" = "wikijs";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/all-in-one/wikijs/assets:/wiki/assets/favicons:rw"
    ];
    ports = [
      "3001:3000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=wikijs"
      "--network=all-in-one_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/all-in-one.env"
    ];
  };
  systemd.services."docker-wikijs" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-all-in-one_default.service"
    ];
    requires = [
      "docker-network-all-in-one_default.service"
    ];
    partOf = [
      "docker-compose-all-in-one-root.target"
    ];
    wantedBy = [
      "docker-compose-all-in-one-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/all-in-one/wikijs/assets"
    ];
  };

  # Networks
  systemd.services."docker-network-all-in-one_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f all-in-one_default";
    };
    script = ''
      docker network inspect all-in-one_default || docker network create all-in-one_default
    '';
    partOf = [ "docker-compose-all-in-one-root.target" ];
    wantedBy = [ "docker-compose-all-in-one-root.target" ];
  };

  # Volumes
  systemd.services."docker-volume-nextcloud_aio_mastercontainer" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect nextcloud_aio_mastercontainer || docker volume create nextcloud_aio_mastercontainer
    '';
    partOf = [ "docker-compose-all-in-one-root.target" ];
    wantedBy = [ "docker-compose-all-in-one-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-all-in-one-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
