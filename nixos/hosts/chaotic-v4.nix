{ config
, garuda-lib
, sources
, pkgs
, ...
}:
let
  wrapperScript = pkgs.writeScriptBin "chaotic-restart" ''
    cd /var/garuda/docker-compose-runner/chaotic-v4/
    docker compose down
    docker compose up -d
  '';
in
{
  imports = sources.defaultModules ++ [ ../modules "${sources.chaotic-portable-builder}/nix/nixos.nix" ];

  # Redis is used to distribute build jobs
  services.redis = {
    vmOverCommit = true;
    servers."chaotic" = {
      bind = "127.0.0.1";
      enable = true;
      port = 6379;
      requirePassFile = "/var/garuda/secrets/chaotic/redis";
    };
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.chaotic-v4 = {
    envfile = garuda-lib.secrets.docker-compose.chaotic-v4;
    source = ../../docker-compose/chaotic-v4;
  };

  # Lock down chaotic-op group to SCP in landing zone
  services.openssh.extraConfig = ''
    Match Group chaotic-op
      AllowTCPForwarding yes
      AllowAgentForwarding no
      X11Forwarding no
      PermitTunnel no
      ForceCommand internal-sftp
      PermitOpen 127.0.0.1:6379
  '';

  # Our package deploying users
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "chaotic-op" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN47/usTQsbmcAuG8CbEkurMDzQJxs+Tf8njI/4iTpKu"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDD2ulefvEwwft9gXj2oUgRl0zWKjG2wkg4xHP1F2p8I" # garuda-build
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwGMzxuAXAHc+DHbOlgRo/FShbF/QXrlJzhl2k/WBHB" # u726578@sms.cluster.infra.ufscar.br
    ];
  };
  users.groups.chaotic-op = { };

  # Expose raw /proc for podman
  systemd.services.expose-raw-proc = {
    description = "Expose clean /proc for podman";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /tmp/raw_proc
      ${pkgs.mount}/bin/mount --bind /proc /tmp/raw_proc
    '';
  };

  networking.firewall.allowedTCPPorts = [
    8080
    config.services.prometheus.port
    config.services.grafana.settings.server.http_port
  ];

  # Enable the user accounts of chaotic maintainers
  garuda-lib.chaoticUsers = true;

  # Allow controlling infra 4.0's containers without root
  environment.systemPackages = [ wrapperScript ];
  security.sudo.extraRules = [
    { users = [ "xiota" ]; commands = [{ command = "${wrapperScript}/bin/chaotic-restart"; options = [ "NOPASSWD" ]; }]; }
  ];

  # Prometheus for monitoring the metrics exported by chaotic-manager
  services.prometheus = {
    enable = true;
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "chaotic-manager";
        static_configs = [
          {
            targets = [
              "127.0.0.1:8080"
            ];
          }
        ];
      }
    ];
  };

  # Grana for displaying Prometheus data
  services.grafana = {
    enable = true;
    provision = {
      enable = false;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            access = "proxy";
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          }
        ];
      };
    };
    settings = {
      auth.anonymous = "enabled";
      analytics = {
        feedback_links_enabled = false;
        reporting_enabled = false;
      };
      live.allowed_origins = [ "https://grafana.garudalinux.net" "http://10.0.5.10" ]; # Needed to get WS to work
      security = {
        admin_email = "team@garudalinux.org";
        cookie_secure = true;
      };
      server = {
        enable_gzip = true;
        http_addr = "10.0.5.140";
        http_port = 3001;
        protocol = "http";
      };
    };
  };

  system.stateVersion = "23.05";
}
