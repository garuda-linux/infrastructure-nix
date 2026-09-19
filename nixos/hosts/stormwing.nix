{
  config,
  garuda-lib,
  lib,
  ...
}:
let
  mon = garuda-lib.monitoring;

  mkTailnetProxy =
    {
      name,
      container,
      port,
      targetPort ? port,
      description,
    }:
    {
      inherit name;
      bind = mon.tailnetIPs.stormwing;
      listen = port;
      target = "${mon.stormwingContainers.${container}}:${toString targetPort}";
      after = [
        "tailscaled.service"
        "container@${container}.service"
      ];
      wants = [ "container@${container}.service" ];
      inherit description;
    };
in
{
  imports = [
    ../modules
    ./../modules/special/hetzner-ex44.nix
  ];

  garuda = garuda-lib.mkMonitoring {
    host = "stormwing";
    lokiAddress = mon.loki.tailnetAddress;
    hostInfo = true;
    motd = false;
    units = [
      "sshd.service"
      "tailscaled.service"
    ];
    exporters = [ "smartctlExporter" ];
  };

  swapDevices = [
    {
      device = "/data_1/swapfile";
      size = 32 * 1024;
    }
  ];

  networking = {
    defaultGateway = "157.180.57.1";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "stormwing";
    interfaces."eth0".ipv4.addresses = [
      {
        address = "157.180.57.51";
        prefixLength = 26;
      }
    ];
    nat.forwardPorts = [
      (garuda-lib.mkNatForward {
        sourcePort = 210;
        destination = "10.0.5.10:22";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 220;
        destination = "10.0.5.20:22";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 80;
        destination = "10.0.5.40:80";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 443;
        destination = "10.0.5.40:443";
      })
      (garuda-lib.mkNatForward {
        sourcePort = 443;
        destination = "10.0.5.40:443";
        proto = "udp";
      })
    ];
  };

  services.garuda-nspawn = {
    dockerCache = "/data_2/dockercache/";

    containers = garuda-lib.mkContainers {
      dir = ./stormwing;
      ips = mon.stormwingContainers;
      containers = {
        chaotic-v4 = {
          mounts = [
            {
              name = "arch-mirror";
              hostPath = "/data_2/containers/arch-mirror/mirror";
              mountPoint = "/srv/http/arch-mirror";
            }
            {
              name = "chaotic";
              hostPath = "/data_2/containers/chaotic-v4/chaotic";
              mountPoint = "/var/garuda/compose-runner/chaotic-v4";
            }
            {
              name = "syncthing";
              hostPath = "/data_2/containers/chaotic-v4/syncthing";
              mountPoint = "/var/lib/syncthing";
            }
            {
              name = "chaotic-v4";
              hostPath = "/data_1/chaotic-v4/";
              mountPoint = "/srv/http/repos";
            }
            {
              name = "iso-builds";
              hostPath = "/data_1/iso/iso";
              mountPoint = "/srv/http/iso";
            }
            {
              name = "garuda-nix-builds";
              hostPath = "/data_1/iso/garuda-nix";
              mountPoint = "/srv/http/garuda-nix";
            }
          ];
          forwardPorts = [
            { containerPort = 873; }
            {
              containerPort = 21027;
              protocol = "udp";
            }
            { containerPort = 22000; }
            {
              containerPort = 22000;
              protocol = "udp";
            }
          ];
          nspawn = {
            enableTun = true;
          };
          needsDocker = true;
          # Only entitled to 1/5 of the CPU resources in case of contention
          cpuWeight = 20;
          ioWeight = 20;
        };

        arch-mirror = {
          mounts = [
            {
              name = "arch-mirror";
              hostPath = "/data_2/containers/arch-mirror/mirror";
              mountPoint = "/srv/http/arch-mirror";
            }
          ];
        };

        github-runner = {
          mounts = [
            {
              name = "token";
              hostPath = config.sops.secrets."compose/github-runner".path;
              mountPoint = "/var/.github-runner.env";
              readOnly = true;
            }
            {
              name = "gitlab-config";
              hostPath = "/data_2/containers/github-runner/gitlab-runner";
              mountPoint = "/etc/gitlab-runner";
            }
            {
              name = "ssh-keys";
              hostPath = "/data_2/containers/github-runner/ssh";
              mountPoint = "/etc/ssh";
            }
            {
              name = "github-cache";
              hostPath = "/data_2/cache/github-runner";
              mountPoint = "/var/cache/github-runner";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 230;
            }
          ];
          nspawn = {
            ephemeral = lib.mkForce true;
          };
          defaults = false;
          needsDocker = true;
          cpuWeight = 20;
          ioWeight = 20;
        };

        firedragon-runner = {
          mounts = [
            {
              name = "firedragon-runner";
              hostPath = "/data_2/containers/firedragon-runner";
              mountPoint = "/var/garuda/compose-runner/firedragon-runner";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 250;
            }
          ];
          nspawn = {
            ephemeral = lib.mkForce true;
          };
          defaults = false;
          needsDocker = true;
          cpuWeight = 10;
          ioWeight = 10;
        };

        gitlab-runner = {
          mounts = [
            {
              name = "nix-cache";
              hostPath = "/data_2/containers/gitlab-runner/nix";
              mountPoint = "/nix";
            }
            {
              name = "gitlab-runner";
              hostPath = "/data_2/containers/gitlab-runner/gitlab-runner";
              mountPoint = "/var/lib/private/gitlab-runner";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 260;
            }
          ];
          needsDocker = true;
          needsKvm = true;
          cpuWeight = 20;
          ioWeight = 20;
        };

        iso-runner = {
          mounts = [
            {
              name = "iso";
              hostPath = "/data_1/iso/";
              mountPoint = "/var/garuda/buildiso";
            }
            {
              name = "cache";
              hostPath = "/data_1/cache/iso-runner";
              mountPoint = "/var/garuda/buildiso/cache";
            }
            {
              name = "pacman_cache";
              hostPath = "/data_1/cache/pacman-cache";
              mountPoint = "/var/cache/pacman/pkg";
            }
          ];
          needsDocker = true;
        };

        web-front = {
          mounts = [
            {
              name = "acme";
              hostPath = "/data_1/containers/web-front/acme";
              mountPoint = "/var/lib/acme";
            }
            {
              name = "nginx";
              hostPath = "/data_1/containers/web-front/nginx";
              mountPoint = "/var/log/nginx";
            }
          ];
          forwardPorts = [
            {
              containerPort = 22;
              hostPort = 240;
            }
          ];
        };
      };
    };
  };

  systemd.services = garuda-lib.mkTunnels (
    [
      (mkTailnetProxy {
        name = "nginx-tailnet-proxy";
        container = "web-front";
        port = mon.ports.nginxExporter;
        description = "Expose web-front nginx exporter to Tailnet only";
      })
      {
        name = "loki-relay";
        bind = mon.bridge.address;
        listen = mon.stormwingLokiRelay.listenPort;
        target = mon.stormwingLokiRelay.target;
        after = [ "tailscaled.service" ];
        description = "Relay stormwing container logs to Loki on aerialis";
      }
    ]
    ++ map (
      p:
      mkTailnetProxy {
        name = "node-exporter-${p.name}-tailnet-proxy";
        container = p.name;
        inherit (p) port;
        targetPort = mon.ports.nodeExporter;
        description = "Expose ${p.name} node exporter to Tailnet only";
      }
    ) mon.stormwingNodeProxies
    ++ map (
      p:
      mkTailnetProxy {
        name = "service-${p.name}-tailnet-proxy";
        inherit (p) container;
        inherit (p) port;
        inherit (p) targetPort;
        description = "Expose ${p.container} ${toString p.targetPort} to Tailnet only";
      }
    ) mon.stormwingServiceProxies
  );

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    mon.ports.nginxExporter
    32041
    39252
  ];

  sops.secrets."compose/github-runner" = { };
}
