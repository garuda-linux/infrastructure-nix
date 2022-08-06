{ lib, pkgs, config, garuda-lib, ... }:
with lib;
let cfg = config.services.garuda-monitoring;
in {
  options.services.garuda-monitoring = {
    enable = mkEnableOption "Garuda monitoring stack";
    
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
