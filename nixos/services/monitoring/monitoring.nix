{ config
, lib
, pkgs
, ...
}:
with lib;
let cfg = config.services.garuda-monitoring;
in {
  options.services.garuda-monitoring = {
    enable = mkEnableOption "Garuda monitoring stack";
    parent = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services = {
      netdata = {
        claimTokenFile = "/var/garuda/secrets/netdata_claim_token";
        config = {
          db = {
            "dbengine disk space MB" = "10240";
            "dbengine multihost disk space MB" = "10240";
            "mode" = "dbengine";
            "update every" = "2";
          };
          ml = { "enabled" = "yes"; };
          web = { "mode" = "none"; };
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
          "go.d/nginx.conf" = mkIf config.services.nginx.enable
            (pkgs.writeText "nginx.conf" ''
              jobs:
                - name: local
                  url: http://localhost/nginx_status
            '');
          "go.d/postgres.conf" = mkIf config.services.postgresql.enable
            (pkgs.writeText "postgres.conf" ''
              jobs:
                - name: web-two
                  dsn: 'postgres://netdata:netdata@localhost:5432/'
            '');
        };
        enable = true;

        # https://github.com/nix-community/nixpkgs.lib/commit/1111263e3da005fe29fd72b87283fc17bfba2d81
        package = pkgs.netdata.override { withCloud = true; };

        # Extra Python packages required for Netdata to function
        python.extraPackages = ps: [ ps.psycopg2 ];
      };

      # Let Netdata poll Nginx' status page 
      nginx.statusPage = true;
    };

    # System packages required for Netdata to function
    systemd.services.netdata.path = with pkgs; [ jq ];
  };
}
