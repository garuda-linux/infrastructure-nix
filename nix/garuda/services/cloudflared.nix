{ config
, lib
, ...
}:
with lib;
let
  cfg = config.services.garuda-cloudflared;
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
      tunnels.garuda-cloudflared-legacy = {
        inherit (cfg) ingress;
        credentialsFile = cfg.tunnel-credentials;
        default = "http_status:404";
      };
    };
  };
}
