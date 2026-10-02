# Global nix-topology module, render with `topology` in the devshell
{ config, pkgs, ... }:
let
  inherit (config.lib.topology) mkConnection mkInternet;
  icons = pkgs.callPackage ./topology-icons.nix { };
in
{
  nodes.internet = mkInternet {
    connections = [
      (mkConnection "aerialis" "eth0")
      (mkConnection "stormwing" "eth0")
      (mkConnection "cloudflare" "edge")
    ];
    interfaces."*".network = "internet";
  };

  networks.internet = {
    name = "Internet";
    style = {
      primaryColor = "#9ca3af";
      secondaryColor = null;
      pattern = "dashed";
    };
  };

  # Most public services are only reachable through Cloudflare (proxied DNS and the web-front tunnels)
  nodes.cloudflare = {
    name = "Cloudflare";
    deviceType = "cloud-server";
    hardware.info = "Proxy, Zero Trust tunnels, R2";
    deviceIcon = "${icons.cloudflare}";
    interfaces.edge = { };
  };

  # Both hosts are Hetzner dedicated servers
  nodes.aerialis.hardware = {
    info = "Hetzner dedicated server";
    image = "${icons.hetzner}";
  };
  nodes.stormwing.hardware = {
    info = "Hetzner dedicated server";
    image = "${icons.hetzner}";
  };

  networks.tailnet = {
    name = "Tailscale";
    cidrv4 = "100.64.0.0/10";
  };
}
