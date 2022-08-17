{ lib, pkgs, config, garuda-lib, ... }:
with lib;
let cfg = config.services.garuda-monitoring;
in {
  options.services.garuda-monitoring = {
    enable = mkEnableOption "Garuda monitoring stack";
    parent = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    services.datadog-agent.enable = true;
    services.datadog-agent.site = "datadoghq.com";
    services.datadog-agent.apiKeyFile = garuda-lib.secrets.datadog.api_key;
    services.datadog-agent.enableLiveProcessCollection = true;
    services.datadog-agent.extraConfig = {
        logs_enabled = true;
        logs_config = {
            container_collect_all = true;
        };
    };
    services.netdata.enable = true;
    services.netdata.config = {
      global = {
        "memory mode" = "none";
        "update every" = "2";
      };
      web = {
        "mode" = "none";
      };
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
      "go.d/nginx.conf" = mkIf config.services.nginx.enable (pkgs.writeText "nginx.conf" ''
jobs:
  - name: local
    url: http://localhost/nginx_status
'');
    };

    services.nginx.statusPage = true;
  };
}
