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
  virtualisation.oci-containers.containers."chaotic-builder" = {
    image = "registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager:latest";
    environment = {
      "BUILDER_HOSTNAME" = "garuda-build";
      "BUILDER_TIMEOUT" = "8600";
      "DATABASE_HOST" = "builds.garudalinux.org";
      "DATABASE_PORT" = "400";
      "REDIS_SSH_HOST" = "builds.garudalinux.org";
      "REDIS_SSH_PORT" = "400";
      "REDIS_SSH_USER" = "package-deployer";
      "SHARED_PATH" = "/var/garuda/docker-compose-runner/chaotic-v4/shared";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/chaotic-v4/shared:/shared:rw"
      "/var/garuda/docker-compose-runner/chaotic-v4/sshkey:/app/sshkey:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "builder" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=chaotic-builder"
      "--network=chaotic-v4-builder_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/chaotic-v4-builder.env"
    ];
  };
  systemd.services."docker-chaotic-builder" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "no";
    };
    after = [
      "docker-network-chaotic-v4-builder_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4-builder_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-builder-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-builder-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/chaotic-v4/shared"
      "/var/garuda/docker-compose-runner/chaotic-v4/sshkey"
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:latest";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "--cleanup" "chaotic-builder" "watchtower" "--interval" "3600" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=watchtower"
      "--network=chaotic-v4-builder_default"
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
      "docker-network-chaotic-v4-builder_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4-builder_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-builder-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-builder-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/run/docker.sock"
    ];
  };

  # Networks
  systemd.services."docker-network-chaotic-v4-builder_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f chaotic-v4-builder_default";
    };
    script = ''
      docker network inspect chaotic-v4-builder_default || docker network create chaotic-v4-builder_default
    '';
    partOf = [ "docker-compose-chaotic-v4-builder-root.target" ];
    wantedBy = [ "docker-compose-chaotic-v4-builder-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-chaotic-v4-builder-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
