{
  garuda-lib,
  pkgs,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda = garuda-lib.mkMonitoring {
    host = "aerialis";
    units = [ "docker.service" ];
  };

  # Enable Docker since we use the official Docker image in /var/discourse
  virtualisation.docker.enable = true;

  topology.self.services.discourse = {
    name = "Discourse";
    icon = "${(pkgs.callPackage ../../topology-icons.nix { }).discourse}";
    info = "https://forum.garudalinux.org";
  };

  # Open required port
  networking.firewall.allowedTCPPorts = [ 80 ];

  system.stateVersion = "25.05";
}
