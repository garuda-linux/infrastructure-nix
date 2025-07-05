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
        };
        configDir = {
          "go.d.conf" = pkgs.writeText "go.d.conf" ''
            enabled: yes
            modules:
              nginx: yes
              postgres: yes
              squidlog: yes
              web_log: yes
          '';
          "python.d.conf" = pkgs.writeText "python.d.conf" ''
            postgres: no
            web_log: no
          '';
          "go.d/nginx.conf" = mkIf config.services.nginx.enable (
            pkgs.writeText "nginx.conf" ''
              jobs:
                - name: local
                  url: http://localhost/nginx_status
            ''
          );
          "go.d/postgres.conf" = mkIf config.services.postgresql.enable (
            pkgs.writeText "postgres.conf" ''
              jobs:
                - name: web-two
                  dsn: 'postgres://netdata:netdata@localhost:5432/'
            ''
          );
        };
        enable = true;

        # https://github.com/nix-community/nixpkgs.lib/commit/1111263e3da005fe29fd72b87283fc17bfba2d81
        package = pkgs.netdataCloud;

        # Extra Python packages required for Netdata to function
        python.extraPackages = ps: [ ps.psycopg2 ];
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
