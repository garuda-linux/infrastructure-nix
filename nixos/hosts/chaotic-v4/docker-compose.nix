# Auto-generated using compose2nix v0.2.2-pre.
{ garuda-lib
, lib
, pkgs
, ...
}:

{
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  # Containers
  virtualisation.oci-containers.containers."caur-backend" = {
    image = "ghcr.io/chaotic-cx/chaotic-next:main";
    environment = {
      "CAUR_DEPLOY_LOG_ID" = "-1002151616973";
      "CAUR_NEWS_ID" = "-1001293714071";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/chaotic-v4/tdlib:/app/tdlib:rw"
    ];
    ports = [
      "3000:3000/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=caur-backend"
      "--network=chaotic-v4_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/chaotic-v4.env"
    ];
  };
  systemd.services."docker-caur-backend" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
      RestartMaxDelaySec = lib.mkOverride 500 "1m";
      RestartSec = lib.mkOverride 500 "100ms";
      RestartSteps = lib.mkOverride 500 9;
    };
    after = [
      "docker-network-chaotic-v4_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/chaotic-v4/tdlib"
    ];
  };
  virtualisation.oci-containers.containers."chaotic-builder" = {
    image = "registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager:latest";
    environment = {
      "BUILDER_HOSTNAME" = "immortalis";
      "CI_CODE_SKIP" = "123";
      "DATABASE_HOST" = "host.docker.internal";
      "DATABASE_PORT" = "22";
      "REDIS_SSH_HOST" = "host.docker.internal";
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
      "--add-host=host.docker.internal:host-gateway"
      "--network-alias=chaotic-builder"
      "--network=chaotic-v4_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/chaotic-v4.env"
    ];
  };
  systemd.services."docker-chaotic-builder" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "no";
    };
    after = [
      "docker-network-chaotic-v4_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/chaotic-v4/shared"
      "/var/garuda/docker-compose-runner/chaotic-v4/sshkey"
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."chaotic-manager" = {
    image = "registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager:latest";
    environment = {
      "CI_CODE_SKIP" = "123";
      "DATABASE_HOST" = "builds.garudalinux.org";
      "DATABASE_PORT" = "400";
      "DATABASE_USER" = "package-deployer";
      "GPG_PATH" = "/var/garuda/docker-compose-runner/chaotic-v4/gnupg";
      "LANDING_ZONE_PATH" = "/var/garuda/docker-compose-runner/chaotic-v4/landing-zone";
      "LOGS_URL" = "https://builds.garudalinux.org/logs/logs.html";
      "PACKAGE_REPOS" = ''{
      "chaotic-aur": {
          "url": "https://gitlab.com/chaotic-aur/pkgbuilds"
      },
      "garuda": {
          "url": "https://gitlab.com/garuda-linux/pkgbuilds"
      },
      "garuda-aur": {
          "url": "https://gitlab.com/garuda-linux/pkgbuilds-aur"
      }
  }'';
      "PACKAGE_REPOS_NOTIFIERS" = ''{
      "chaotic-aur": {
          "id": "54867625",
          "token": "${garuda-lib.secrets.chaotic.gl-pat-chaotic}",
          "check_name": "chaotic-aur: %pkgbase%"
      },
      "garuda": {
          "id": "48461689",
          "token": "${garuda-lib.secrets.chaotic.gl-pat-garuda}",
          "check_name": "garuda: %pkgbase%"
      },
      "garuda-aur": {
          "id": "52092196",
          "token": "${garuda-lib.secrets.chaotic.gl-pat-garuda}",
          "check_name": "garuda: %pkgbase%"
      }
  }'';
      "PACKAGE_TARGET_REPOS" = ''{
      "chaotic-aur": {
          "extra_repos": [
              {
                  "name": "chaotic-aur",
                  "servers": [
                      "https://builds.garudalinux.org/chaotic-v4/x86_64"
                  ]
              }
          ],
          "extra_keyrings": [
              "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
          ]
      },
      "garuda": {
          "extra_repos": [
              {
                  "name": "garuda",
                  "servers": [
                      "https://builds.garudalinux.org/repos/garuda/x86_64"
                  ]
              },
              {
                  "name": "chaotic-aur",
                  "servers": [
                      "https://builds.garudalinux.org/repos/chaotic-aur/x86_64"
                  ]
              }
          ],
          "extra_keyrings": [
              "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
          ]
      },
      "garuda-aur": {
          "extra_repos": [
              {
                  "name": "garuda",
                  "servers": [
                      "https://builds.garudalinux.org/repos/garuda/x86_64"
                  ]
              },
              {
                  "name": "chaotic-aur",
                  "servers": [
                      "https://builds.garudalinux.org/repos/chaotic-aur/x86_64"
                  ]
              }
          ],
          "extra_keyrings": [
              "https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst"
          ]
      }
  }'';
      "REDIS_SSH_HOST" = "host.docker.internal";
      "REDIS_SSH_USER" = "package-deployer";
      "REPO_PATH" = "/srv/http/repos";
    };
    volumes = [
      "/var/garuda/docker-compose-runner/chaotic-v4/sshkey:/app/sshkey:rw"
      "/srv/http/repos:/repo_root:rw"
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    ports = [
      "8080:8080/tcp"
    ];
    cmd = [ "database" "--web-port" "8080" ];
    log-driver = "journald";
    extraOptions = [
      "--add-host=host.docker.internal:host-gateway"
      "--network-alias=chaotic-manager"
      "--network=chaotic-v4_default"
    ];
    environmentFiles = [
      "/var/garuda/secrets/docker-compose/chaotic-v4.env"
    ];
  };
  systemd.services."docker-chaotic-manager" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "no";
    };
    after = [
      "docker-network-chaotic-v4_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/garuda/docker-compose-runner/chaotic-v4/sshkey"
      "/srv/http/repos"
      "/var/run/docker.sock"
    ];
  };
  virtualisation.oci-containers.containers."watchtower" = {
    image = "containrrr/watchtower:latest";
    volumes = [
      "/var/run/docker.sock:/var/run/docker.sock:rw"
    ];
    cmd = [ "--cleanup" "chaotic-builder" "chaotic-manager" "watchtower" "caur-backend" "--interval" "3600" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=watchtower"
      "--network=chaotic-v4_default"
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
      "docker-network-chaotic-v4_default.service"
    ];
    requires = [
      "docker-network-chaotic-v4_default.service"
    ];
    partOf = [
      "docker-compose-chaotic-v4-root.target"
    ];
    wantedBy = [
      "docker-compose-chaotic-v4-root.target"
    ];
    unitConfig.RequiresMountsFor = [
      "/var/run/docker.sock"
    ];
  };

  # Networks
  systemd.services."docker-network-chaotic-v4_default" = {
    path = [ pkgs.docker ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "docker network rm -f chaotic-v4_default";
    };
    script = ''
      docker network inspect chaotic-v4_default || docker network create chaotic-v4_default
    '';
    partOf = [ "docker-compose-chaotic-v4-root.target" ];
    wantedBy = [ "docker-compose-chaotic-v4-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."docker-compose-chaotic-v4-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
