{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrNames
    concatLines
    filterAttrs
    mapAttrs'
    mkIf
    mkMerge
    nameValuePair
    ;
  svc = config.services;
  icons = pkgs.callPackage ../topology-icons.nix { };
in
{
  # Services nix-topology does not extract on its own
  topology.self.services = mkMerge [
    (mkIf config.virtualisation.docker.enable {
      docker = {
        name = "Docker";
        icon = "${icons.docker}";
      };
    })
    (mkIf (config.mailserver.enable or false) {
      mailserver = {
        name = "Mailserver";
        icon = "${icons.postfix}";
        info = config.mailserver.fqdn;
        details.domains.text = concatLines config.mailserver.domains;
      };
    })
    (mkIf svc.rspamd.enable {
      rspamd.name = "Rspamd";
    })
    (mkIf svc.roundcube.enable {
      roundcube = {
        name = "Roundcube";
        icon = "${icons.roundcube}";
        info = svc.roundcube.hostName;
      };
    })
    (mapAttrs' (
      name: server:
      nameValuePair "redis-${name}" {
        name = "Redis (${name})";
        icon = "${icons.redis}";
        info =
          if server.port == 0 then "unix socket" else "${toString server.bind}:${toString server.port}";
      }
    ) (filterAttrs (_: server: server.enable) svc.redis.servers))
    (mkIf svc.prometheus.alertmanager.enable {
      alertmanager = {
        name = "Alertmanager";
        icon = "${icons.alertmanager}";
        info = "${svc.prometheus.alertmanager.listenAddress}:${toString svc.prometheus.alertmanager.port}";
      };
    })
    (mkIf svc.n8n.enable {
      n8n = {
        name = "n8n";
        icon = "${icons.n8n}";
        info = svc.n8n.environment.N8N_EDITOR_BASE_URL or "";
      };
    })
    (mkIf svc.syncthing.enable {
      syncthing = {
        name = "Syncthing";
        icon = "${icons.syncthing}";
        info = svc.syncthing.guiAddress;
      };
    })
    (mkIf svc.rsyncd.enable {
      rsyncd = {
        name = "rsyncd";
        info = "port ${toString svc.rsyncd.port}";
      };
    })
    (mkIf (svc.garuda-cloudflared.enable or false) {
      cloudflared = {
        name = "Cloudflare tunnel";
        icon = "${icons.cloudflared}";
        details.ingress.text = concatLines (attrNames svc.garuda-cloudflared.ingress);
      };
    })
    (mkIf (svc.garuda-arch-mirror.enable or false) {
      arch-mirror = {
        name = "Arch Linux mirror";
        icon = "${icons.arch-linux}";
        info = svc.garuda-arch-mirror.upstreamUrl;
      };
    })
    (mkIf (svc.garuda-iso.enable or false) {
      buildiso = {
        name = "Garuda ISO builder";
        icon = "${icons.garuda-linux}";
      };
    })
    (mkIf svc.gitlab-runner.enable {
      gitlab-runner = {
        name = "GitLab runner";
        icon = "${icons.gitlab}";
        details.runners.text = concatLines (attrNames svc.gitlab-runner.services);
      };
    })
    (mapAttrs' (
      name: runner:
      nameValuePair "github-runner-${name}" {
        name = "GitHub runner (${name})";
        icon = "${icons.github-light}";
        info = runner.url;
      }
    ) (filterAttrs (_: runner: runner.enable) svc.github-runners))
    (mkIf svc.borgmatic.enable {
      borgmatic = {
        name = "Borgmatic";
        icon = "${icons.borgmatic}";
      };
    })
  ];

  topology.self.interfaces.tailscale0 = mkIf svc.tailscale.enable {
    network = "tailnet";
    type = "wireguard";
    virtual = true;
  };
}
