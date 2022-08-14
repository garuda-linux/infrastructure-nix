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
    services.datadog-agent.apiKeyFile = pkgs.writeText "datadog-apikey" garuda-lib.datadog.api_key;
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
    api key = ${garuda-lib.netdata.stream_token}
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
    };

/*     virtualisation.oci-containers.containers = {
      deepfence_agent = {
        image = "deepfenceio/deepfence_agent_ce:latest";
        extraOptions = [ "--pull=always" "--pid=host" "--network=host" "--privileged=true" ];
        volumes = [
          "/sys/kernel/debug:/sys/kernel/debug:rw"
          "/var/run/docker.sock:/var/run/docker.sock"
          "/:/fenced/mnt/host/:ro"
        ];
      };
    };
    
    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";*/
  };
}
