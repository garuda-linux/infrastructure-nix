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
      "garuda-arch-mirror.service"
      "nginx.service"
    ];
  };

  services.garuda-arch-mirror = {
    enable = true;
    upstreamUrl = "rsync://f.matthieul.dev/mirror/archlinux/";
    lastupdateUrl = "https://f.matthieul.dev/mirror/archlinux/lastupdate";
    tls = false;
    rcloneConfig = config.sops.secrets."cloudflare/r2_rclone".path;
    rcloneDest = "r2:/mirror/arch";
  };

  sops.secrets = garuda-lib.mkSecrets [ "cloudflare/r2_rclone" ];

  system.stateVersion = "25.05";
}
