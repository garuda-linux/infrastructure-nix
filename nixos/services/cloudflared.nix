{ config
, inputs
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.garuda-cloudflared;

  # https://github.com/cloudflare/cloudflared/issues/1054 - until PR with fix in nixos-unstable
  # which is this one: https://github.com/NixOS/nixpkgs/pull/263841/files
  cloudflared = pkgs.callPackage "${toString inputs.nixpkgs}/pkgs/applications/networking/cloudflared" {
    buildGoModule = pkgs.buildGo120Module;
  };
in
{
  options.services.garuda-cloudflared = {
    enable = mkEnableOption "Garuda legacy cloudflared options";
    ingress = mkOption { type = types.attrs; };
    tunnel-credentials = mkOption { type = types.path; };
  };

  config = mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      package = cloudflared;
      tunnels.garuda-cloudflared-legacy = {
        inherit (cfg) ingress;
        credentialsFile = cfg.tunnel-credentials;
        default = "http_status:404";
      };
    };
  };
}
