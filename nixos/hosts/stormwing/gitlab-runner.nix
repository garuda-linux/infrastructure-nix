{
  config,
  garuda-lib,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda = garuda-lib.mkMonitoring {
    host = "stormwing";
    units = [
      "docker.service"
      "gitlab-runner.service"
    ];
  };

  networking.firewall.interfaces."eth0".allowedTCPPorts = [ 9252 ];

  services.garuda-gitlab-runner = {
    enable = true;
    runners = {
      stormwing-nix-caching = {
        authenticationTokenConfigFile =
          config.sops.secrets."gitlab-runner/runners/stormwing-nix-caching".path;
        nix-caching.enable = true;
        kvm.enable = true;
      };
      stormwing-nix-dind = {
        authenticationTokenConfigFile = config.sops.secrets."gitlab-runner/runners/stormwing-nix-dind".path;
        nix-caching.enable = true;
        kvm.enable = true;
      };
    };
  };

  sops.secrets = garuda-lib.mkSecrets [
    "gitlab-runner/runners/stormwing-nix-caching"
    "gitlab-runner/runners/stormwing-nix-dind"
  ];

  system.stateVersion = "26.11";
}
