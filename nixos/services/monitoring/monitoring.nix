{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.garuda-monitoring;
in
{
  options.services.garuda-monitoring = {
    enable = mkEnableOption "Garuda monitoring stack";
    parent = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services = {
      netdata = {
        claimTokenFile = config.sops.secrets."netdata/claim_token".path;
        config = {
          db = {
            "mode" = "dbengine";
            "update every" = "2";
            "storage tiers" = "3";
            "dbengine tier 0 retention size" = "1GiB";
            "dbengine tier 0 retention time" = "14d";
            "dbengine tier 1 retention size" = "1GiB";
            "dbengine tier 1 retention time" = "3m";
            "dbengine tier 2 retention size" = "1GiB";
            "dbengine tier 2 retention time" = "2y";
          };
          ml = {
            "enabled" = "yes";
          };
          web = {
            "mode" = "none";
          };
          "plugin:cgroups" = {
            "enable by default cgroups matching" = "!*payload* !*user.slice* *";
          };
          "plugin:perf" = {
            "update every" = "0";
          };
          "plugin:proc:diskspace" = {
            "exclude space metrics on paths" = "/run/nixos-containers/* /run/user/*";
          };
        };
        configDir = {
          "go.d.conf" = pkgs.writeText "go.d.conf" ''
            enabled: yes
            default_run: yes
            modules:
              nginx: yes
              squidlog: yes
              web_log: yes
              postgres: yes
              redis: yes
              docker: no
              docker_engine: no
              systemdunits: yes
              postfix: yes
              dovecot: yes
              rspamd: yes
              filecheck: yes
              smartctl: yes
              sensors: yes
              hddtemp: yes
          '';
          "python.d.conf" = pkgs.writeText "python.d.conf" ''
            postgres: no
            web_log: no
            sensors: yes
            hddtemp: yes
          '';
          "go.d/nginx.conf" = mkIf config.services.nginx.enable (
            pkgs.writeText "nginx.conf" ''
              jobs:
                - name: local
                  url: http://localhost/nginx_status
            ''
          );
        };
        enable = true;
      };

      # Let Netdata poll Nginx' status page
      nginx.statusPage = true;
    };

    # System packages required for Netdata to function
    systemd.services.netdata.path = with pkgs; [ jq ];

    sops.secrets."netdata/claim_token" = {
      mode = "0600";
      owner = "netdata";
      group = "netdata";
    };
  };
}
