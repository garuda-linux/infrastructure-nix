{
  config,
  lib,
  sources,
  pkgs,
  ...
}:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ../../secrets/buildtime.json);
  nginxReverseProxySettingsPkg = pkgs.writeText "garuda-proxy-settings.conf" ''
    proxy_redirect          off;
    proxy_connect_timeout   60s;
    proxy_send_timeout      60s;
    proxy_read_timeout      60s;
    proxy_http_version      1.1;
    proxy_set_header        Upgrade $http_upgrade;
    proxy_set_header        Connection $connection_upgrade;
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $remote_addr;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $host;
  '';
  nginxReverseProxySettings = ''
    include ${nginxReverseProxySettingsPkg};
  '';
  setRealIpFromConfigPkg = pkgs.writeText "garuda-cf-real-ip.conf" (
    lib.concatMapStrings (ip: ''
      set_real_ip_from ${ip};
    '') (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4))
    + "\nreal_ip_header CF-Connecting-IP;"
  );
  setRealIpFromConfig = ''
    include ${setRealIpFromConfigPkg};
  '';
  allowOnlyCloudflared =
    config:
    (
      config
      // {
        listen = [
          {
            addr = "127.0.0.1";
            port = 80;
          }
        ];
        extraConfig = (config.extraConfig or "") + ''
          real_ip_header CF-Connecting-IP;
          set_real_ip_from 127.0.0.1;
        '';
      }
    );
  # This is technically unecessary, but safety!
  # This refers to the Cloudflare service "Cloudflare Access" to allow only specified users to access the service
  allowOnlyCloudflareZerotrust =
    base_config:
    let
      config = allowOnlyCloudflared base_config;
    in
    config
    // {
      extraConfig = config.extraConfig + ''
        ssl_verify_client on;
        underscores_in_headers off;
        ssl_client_certificate ${sources.cloudflare-authenticated_origin_pull_ca};
      '';
      locations = lib.mapAttrs (
        _: location:
        location
        // {
          extraConfig = ''
            if ($http_cf_access_authenticated_user_email = "") {
                return 403;
            }
          ''
          + (location.extraConfig or "");
        }
      ) config.locations;
    };
  generateCloudflaredIngress =
    virtualHosts:
    let
      destination = "http://127.0.0.1:80";
      toIngress =
        array:
        map (host: {
          name = host;
          value = destination;
        }) array;
      isCloudflared = values: values ? listen && values.listen == (allowOnlyCloudflared { }).listen;
    in
    builtins.listToAttrs (
      lib.flatten (
        lib.mapAttrsToList (
          host: values:
          lib.optionals (isCloudflared values) (toIngress ([ host ] ++ (values.serverAliases or [ ])))
        ) virtualHosts
      )
    );

  # Central monitoring endpoints for reuse across hosts and containers
  monitoring = rec {
    ports = {
      grafana = 3010;
      prometheus = 9090;
      alertmanager = 9093;
      loki = 3030;
      nodeExporter = 3021;
      nginxExporter = 9113;
      smartctlExporter = 9633;
      borgmaticExporter = 9996;
      redisExporter = 9121;
      postfixExporter = 9154;
      dovecotMetrics = 9900;
      gitlabRunnerMetrics = 9252;
      cloudflaredMetrics = 20241;
    };

    # MagicDNS names on the Tailnet
    tailnetHosts = {
      aerialis = "aerialis";
      stormwing = "stormwing";
    };

    # Literal Tailnet IPs for socat bind=. MagicDNS names must NOT be
    # used there: on the host itself the own hostname resolves to
    # 127.0.0.2 via /etc/hosts, so the proxy would listen on loopback
    # and refuse Tailnet traffic.
    tailnetIPs = {
      aerialis = "100.100.1.20";
      stormwing = "100.100.1.10";
    };

    tailnetDNS = "100.100.100.100";
    tailnetDomain = "kanyu-bushi.ts.net";

    loki = {
      tailnetAddress = tailnetHosts.aerialis;
      containerAddress = aerialisContainers.monitoring;
    };

    aerialisContainers = {
      web-front = "10.0.5.10";
      postgres = "10.0.5.20";
      mastodon = "10.0.5.30";
      forum = "10.0.5.40";
      docker-proxied = "10.0.5.50";
      docker = "10.0.5.60";
      chaotic-backend = "10.0.5.70";
      mail = "10.0.5.80";
      n8n = "10.0.5.90";
      monitoring = "10.0.5.100";
    };
    stormwingContainers = {
      chaotic-v4 = "10.0.5.10";
      iso-runner = "10.0.5.20";
      github-runner = "10.0.5.30";
      web-front = "10.0.5.40";
      firedragon-runner = "10.0.5.50";
      arch-mirror = "10.0.5.60";
      gitlab-runner = "10.0.5.70";
    };

    # Non-node metrics of stormwing containers, exposed on stormwing's
    # Tailnet IP for the same reason as above.
    stormwingServiceProxies = [
      {
        name = "gitlab-runner-metrics";
        container = "gitlab-runner";
        port = 39252;
        targetPort = ports.gitlabRunnerMetrics;
      }
      {
        name = "web-front-cloudflared";
        container = "web-front";
        port = 32041;
        targetPort = ports.cloudflaredMetrics;
      }
    ];

    # Stormwing containers ship logs via fluent-bit to the bridge address;
    # the stormwing host relays it to the aerialis Tailnet IP. This then
    # forwards into the monitoring container via loki-tailnet-proxy.
    stormwingLokiRelay = {
      listenPort = ports.loki;
      target = "${tailnetIPs.aerialis}:${toString ports.loki}";
    };

    # Node exporter of each stormwing container, exposed on stormwing's
    # Tailnet IP. The monitoring container can't reach stormwing's
    # bridge directly, so we need to relay it.
    stormwingNodeProxies = [
      {
        name = "chaotic-v4";
        port = 31010;
      }
      {
        name = "iso-runner";
        port = 31020;
      }
      {
        name = "github-runner";
        port = 31030;
      }
      {
        name = "web-front";
        port = 31040;
      }
      {
        name = "firedragon-runner";
        port = 31050;
      }
      {
        name = "arch-mirror";
        port = 31060;
      }
      {
        name = "gitlab-runner";
        port = 31070;
      }
    ];

    bridge = {
      interface = "br0";
      address = "10.0.5.1";
    };

    # Chaotic mirrors on the Tailnet.
    chaoticMirrors = [
      {
        name = "amsterdam-nl";
        ip = "100.100.125.21";
      }
      {
        name = "apodaca-mx";
        ip = "100.64.184.35";
      }
      {
        name = "cardiff-gb";
        ip = "100.97.49.121";
      }
      {
        name = "chuncheon-kr";
        ip = "100.81.226.85";
      }
      {
        name = "dubai-ae";
        ip = "100.67.143.31";
      }
      {
        name = "frankfurt-de";
        ip = "100.120.106.99";
      }
      {
        name = "guarulhos-br";
        ip = "100.65.64.13";
      }
      {
        name = "hyderabad-in";
        ip = "100.65.165.120";
      }
      {
        name = "jeddah-sa";
        ip = "100.102.195.64";
      }
      {
        name = "jerusalem-il";
        ip = "100.126.217.88";
      }
      {
        name = "johannesburg-za";
        ip = "100.74.19.73";
      }
      {
        name = "la-canada-mx";
        ip = "100.92.190.86";
      }
      {
        name = "london-gb";
        ip = "100.65.135.124";
      }
      {
        name = "madrid-es";
        ip = "100.116.82.81";
      }
      {
        name = "marseille-fr";
        ip = "100.119.174.74";
      }
      {
        name = "masdar-city-ae";
        ip = "100.106.185.24";
      }
      {
        name = "melbourne-au";
        ip = "100.114.165.109";
      }
      {
        name = "montreal-ca";
        ip = "100.85.139.124";
      }
      {
        name = "mumbai-in";
        ip = "100.70.130.65";
      }
      {
        name = "osaka-jp";
        ip = "100.81.176.55";
      }
      {
        name = "paris-fr";
        ip = "100.123.14.23";
      }
      {
        name = "phoenix-us";
        ip = "100.66.202.108";
      }
      {
        name = "san-jose-us";
        ip = "100.100.26.46";
      }
      {
        name = "santiago-cl";
        ip = "100.108.0.38";
      }
      {
        name = "sao-paulo-br";
        ip = "100.86.182.87";
      }
      {
        name = "seoul-kr";
        ip = "100.96.112.21";
      }
      {
        name = "siziano-it";
        ip = "100.90.61.39";
      }
      {
        name = "stockholm-se";
        ip = "100.117.198.121";
      }
      {
        name = "sydney-au";
        ip = "100.99.21.110";
      }
      {
        name = "tokyo-jp";
        ip = "100.85.247.52";
      }
      {
        name = "toronto-ca";
        ip = "100.117.164.61";
      }
      {
        name = "vinhedo-br";
        ip = "100.113.84.25";
      }
      {
        name = "zurich-ch";
        ip = "100.118.191.84";
      }
    ];

    chaoticMirrorTargets = map (m: {
      inherit (m) name;
      target = "${m.name}:${toString ports.nodeExporter}";
    }) chaoticMirrors;

    nodeHostTargets = [
      {
        name = "aerialis";
        target = "${bridge.address}:${toString ports.nodeExporter}";
      }
      {
        name = "stormwing";
        target = "${tailnetHosts.stormwing}:${toString ports.nodeExporter}";
      }
    ];

    # A web-front exists on both hosts, so qualify it (same convention
    # as the Loki host labels). All other names are unique already.
    nodeContainerTargets = lib.mapAttrsToList (name: ip: {
      target = "${ip}:${toString ports.nodeExporter}";
      instance = if name == "web-front" then "web-front-aerialis" else name;
    }) aerialisContainers;

    stormwingNodeContainerTargets = map (p: {
      target = "${tailnetHosts.stormwing}:${toString p.port}";
      instance = if p.name == "web-front" then "web-front-stormwing" else p.name;
    }) stormwingNodeProxies;

    nginxTargets = [
      "${aerialisContainers.web-front}:${toString ports.nginxExporter}"
      "${tailnetHosts.stormwing}:${toString ports.nginxExporter}"
    ];

    cloudflaredTargets = [
      "${aerialisContainers.web-front}:${toString ports.cloudflaredMetrics}"
      "${tailnetHosts.stormwing}:32041"
    ];

    gitlabRunnerTargets = [
      "${tailnetHosts.stormwing}:39252"
    ];

    smartctlTargets = [
      {
        name = "aerialis";
        inherit (bridge) address;
      }
      {
        name = "stormwing";
        address = tailnetHosts.stormwing;
      }
    ];

    borgmaticTargets = [
      {
        name = "aerialis";
        inherit (bridge) address;
      }
    ];
  };
in
{
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { };
  };
  config = {
    _module.args.garuda-lib = config.garuda-lib;
    # Defaults
    garuda-lib = {
      behind_proxy = false;
      inherit
        setRealIpFromConfig
        nginxReverseProxySettings
        allowOnlyCloudflared
        allowOnlyCloudflareZerotrust
        generateCloudflaredIngress
        monitoring
        ;
      minimalContainer = false;
      chaoticUsers = false;
      unifiedUID = false;
      sshkeys = {
        ed25519 = "/etc/ssh/ssh_host_ed25519_key";
        rsa = "/etc/ssh/ssh_host_rsa_key";
      };
      inherit secrets;
      xslt_style = ./static/style.xslt;
      dns = {
        stormwing = "157.180.57.51";
        aerialis = "157.180.57.100";
      };
    };
  };
}
