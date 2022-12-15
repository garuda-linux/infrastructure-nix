{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.garuda-cloudflared;
  ingress_lines = concatStringsSep "\n" (mapAttrsToList (hostname: target:
    "  " + ''
      - hostname: ${hostname}
          service: ${target}'') cfg.ingress);
  cloudflared_config = pkgs.writeText "cloudflared-config" ''
    tunnel: ${cfg.tunnel-id}
    credentials-file: ${cfg.tunnel-credentials}

    ingress:
    ${ingress_lines}
      - service: http_status:404
  '';
in {
  options.services.garuda-cloudflared = {
    enable = mkEnableOption "Garuda Meshagent";
    ingress = mkOption { type = types.attrs; };
    tunnel-credentials = mkOption { type = types.path; };
    tunnel-id = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    systemd.services.garuda-cloudflared = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart =
          "${pkgs.unstable.cloudflared}/bin/cloudflared tunnel --config=${cloudflared_config} --no-autoupdate run";
        Restart = "always";
        ProtectSystem = "strict";
        ProtectHome = "true";
        PrivateTmp = "true";
      };
    };
  };
}
