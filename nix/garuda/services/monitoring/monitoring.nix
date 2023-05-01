{ config
, pkgs
, lib
, garuda-lib
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
    services.netdata.enable = true;
    services.netdata.config = {
      global = {
        "memory mode" = "none";
        "update every" = "2";
      };
      ml = { "enabled" = "yes"; };
      web = { "mode" = "none"; };
    };
    services.netdata.configDir = {
      "stream.conf" = pkgs.writeText "stream.conf" ''
        [stream]
            api key = ${garuda-lib.secrets.netdata.stream_token}
            buffer size bytes = 15728640
            destination = ${cfg.parent}
            enable compression = yes
            enabled = yes
            timeout seconds = 360

        [logs]
            debug log = none
            error log = none
            access log = none
      '';
      "go.d.conf" = pkgs.writeText "go.d.conf" ''
        enabled: yes
        modules:
          nginx: yes
          postgres: yes
          vsphere: yes
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
              dsn: 'postgres://netdata:netdata@127.0.0.1:5432/'
        '');
    };

    # Extra Python & system packages required for Netdata to function
    services.netdata.python.extraPackages = ps: [ ps.psycopg2 ];
    systemd.services.netdata = { path = with pkgs; [ jq ]; };

    # Let Netdata poll Nginx' status page 
    services.nginx.statusPage = true;
  };
}
