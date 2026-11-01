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
      };

      # Privileged and root (no userns remap), with /dev/kvm.
      # Set to "protected" in GitLab, so only main branch jobs reach it.
      stormwing-nix-privileged = {
        authenticationTokenConfigFile = config.sops.secrets."gitlab-runner/runners/stormwing-nix-privileged".path;
        nix-privileged.enable = true;
        kvm.enable = true;
      };
    };
    volumeCleanup.enable = true;
  };

  sops.secrets = garuda-lib.mkSecrets [
    "gitlab-runner/runners/stormwing-nix-caching"
    "gitlab-runner/runners/stormwing-nix-privileged"
  ];

  system.stateVersion = "26.11";
}
