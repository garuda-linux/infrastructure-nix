{
  config,
  lib,
  pkgs,
  ...
}:
let
  monitoring = config.garuda-lib.monitoring;
  inherit (lib)
    concatStringsSep
    genAttrs
    listToAttrs
    mapAttrs
    nameValuePair
    optional
    optionalAttrs
    optionalString
    recursiveUpdate
    ;

  mkBindMount =
    {
      name,
      hostPath,
      mountPoint,
      readOnly ? false,
    }:
    nameValuePair name {
      inherit hostPath mountPoint;
      isReadOnly = readOnly;
    };

  mkTunnel =
    {
      bind,
      listen,
      target,
      after ? [ "tailscaled.service" ],
      wants ? [ ],
      description ? "Expose port ${toString listen} to Tailnet only",
    }:
    {
      inherit description after wants;
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString listen},bind=${bind},fork,reuseaddr TCP:${target}";
        Restart = "always";
        RestartSec = 5;
        DynamicUser = true;
      };
    };

  helpers = rec {
    inherit mkBindMount mkTunnel;

    mkBindMounts = mounts: listToAttrs (map mkBindMount mounts);

    mkForwardPort =
      {
        containerPort,
        hostPort ? containerPort,
        protocol ? "tcp",
      }:
      {
        inherit containerPort hostPort protocol;
      };

    mkNatForward =
      {
        sourcePort,
        destination,
        proto ? "tcp",
      }:
      {
        inherit sourcePort destination proto;
        loopbackIPs = [ config.garuda-lib.dns.${config.networking.hostName} ];
      };

    # Generating both sides at once keeps `requires` and `before` in sync.
    mkContainerOrdering =
      { root, containers }:
      listToAttrs (
        map (c: nameValuePair "container@${c}" { requires = [ "container@${root}.service" ]; }) containers
      )
      // {
        "container@${root}".before = map (c: "container@${c}.service") containers;
      };

    mkSecrets = names: genAttrs names (_: { });

    mkTunnels =
      tunnels: listToAttrs (map (t: nameValuePair t.name (mkTunnel (removeAttrs t [ "name" ]))) tunnels);

    mkContainer =
      spec:
      {
        inherit (spec) config ipAddress;
        extraOptions =
          optionalAttrs (spec.mounts or [ ] != [ ]) { bindMounts = mkBindMounts spec.mounts; }
          // optionalAttrs (spec.forwardPorts or [ ] != [ ]) {
            forwardPorts = map mkForwardPort spec.forwardPorts;
          }
          // (spec.nspawn or { })
          // (spec.extraOptions or { });
      }
      // removeAttrs spec [
        "config"
        "ipAddress"
        "mounts"
        "forwardPorts"
        "nspawn"
        "extraOptions"
      ];

    mkContainers =
      {
        dir,
        ips,
        containers,
      }:
      mapAttrs (
        name: spec:
        mkContainer (
          spec
          // {
            ipAddress = ips.${name};
            config = import (dir + "/${name}.nix");
          }
        )
      ) containers;

    # lokiAddress defaults to what a sibling container uses: the stormwing
    # containers reach Loki over the bridge, the aerialis ones directly.
    mkMonitoring =
      {
        host,
        lokiAddress ? (
          if host == "stormwing" then monitoring.bridge.address else monitoring.loki.containerAddress
        ),
        units ? [ ],
        exporters ? [ ],
        extraPrometheus ? { },
        hostInfo ? false,
      }:
      {
        monitoring = {
          enable = true;
          prometheus = recursiveUpdate (genAttrs ([ "nodeExporter" ] ++ exporters) (_: {
            enable = true;
          })) extraPrometheus;
          fluent-bit = {
            enable = true;
            inherit lokiAddress;
            lokiPort = monitoring.ports.loki;
            extraSystemdUnits = units;
          };
        }
        // optionalAttrs hostInfo { hostInfo.enable = true; };
      };

    mkProxyVhost =
      {
        upstream,
        acmeHost ? "garudalinux.org",
        location ? "/",
        realIp ? true,
        prologue ? "",
        locationExtraConfig ? "",
        extraLocations ? { },
        serverAliases ? [ ],
      }:
      {
        addSSL = true;
        http3 = true;
        quic = true;
        useACMEHost = acmeHost;
        extraConfig =
          optionalString (prologue != "") (prologue + "\n")
          + concatStringsSep "\n" (
            optional realIp config.garuda-lib.setRealIpFromConfig
            ++ [ config.garuda-lib.nginxReverseProxySettings ]
          )
          + "\n";
        locations = {
          ${location} = {
            proxyPass = upstream;
          }
          // optionalAttrs (locationExtraConfig != "") { extraConfig = locationExtraConfig; };
        }
        // extraLocations;
      }
      // optionalAttrs (serverAliases != [ ]) { inherit serverAliases; };

    mkCatchAllVhost =
      {
        acmeHost ? "garudalinux.org",
      }:
      {
        addSSL = true;
        http3 = true;
        quic = true;
        useACMEHost = acmeHost;
        extraConfig = ''
          log_not_found off;
          return 404;
        '';
      };

    mkCloudflaredVhost =
      args: config.garuda-lib.allowOnlyCloudflared (mkProxyVhost (args // { realIp = false; }));

    mkZerotrustVhost =
      args: config.garuda-lib.allowOnlyCloudflareZerotrust (mkProxyVhost (args // { realIp = false; }));

    mkWebFront =
      { host, vhosts }:
      {
        garuda =
          recursiveUpdate
            (mkMonitoring {
              inherit host;
              units = [
                "cloudflared-tunnel-garuda-cloudflared-legacy.service"
                "nginx.service"
              ];
              exporters = [ "nginxExporter" ];
            })
            {
              monitoring.fluent-bit.nginxAccessLog = {
                enable = true;
                hostLabel = "web-front-${host}";
              };
            };
        systemd.services.cloudflared-metrics-proxy = mkTunnel {
          bind = monitoring."${host}Containers".web-front;
          listen = monitoring.ports.cloudflaredMetrics;
          target = "127.0.0.1:${toString monitoring.ports.cloudflaredMetrics}";
          after = [ "cloudflared-tunnel-garuda-cloudflared-legacy.service" ];
          wants = [ "cloudflared-tunnel-garuda-cloudflared-legacy.service" ];
          description = "Expose cloudflared metrics on the container address";
        };
        networking.firewall.interfaces."eth0".allowedTCPPorts = [ monitoring.ports.cloudflaredMetrics ];
        services.nginx = {
          enable = true;
          statusPage = true;
          virtualHosts = vhosts;
        };
        services.garuda-cloudflared = {
          enable = true;
          ingress = config.garuda-lib.generateCloudflaredIngress vhosts;
          tunnel-credentials = config.sops.secrets."cloudflare/tunnels/${host}".path;
        };
        sops.secrets."cloudflare/tunnels/${host}" = { };
      };

    # Untrusted CI containers: no default modules, no user flake config.
    mkUntrustedRunner =
      {
        user,
        home,
        key,
        units,
        runners,
      }:
      {
        garuda =
          mkMonitoring {
            host = "stormwing";
            inherit units;
          }
          // {
            services.compose-runner = runners;
          };
        virtualisation.docker = {
          autoPrune.enable = true;
          autoPrune.flags = [ "-a" ];
        };
        services.openssh.enable = true;
        users = {
          allowNoPasswordLogin = true;
          mutableUsers = false;
          users.${user} = {
            inherit home;
            isNormalUser = true;
            openssh.authorizedKeys.keyFiles = [ key ];
          };
        };
        nix.settings.trusted-users = [ user ];
        security.sudo.extraRules = [
          {
            users = [ user ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
        systemd.oomd = {
          enable = true;
          enableSystemSlice = true;
          enableUserSlices = true;
        };
      };
  };
in
{
  config.garuda-lib = helpers;
}
