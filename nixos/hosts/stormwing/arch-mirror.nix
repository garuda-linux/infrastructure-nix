{
  config,
  lib,
  pkgs,
  sources,
  ...
}:
{
  imports = sources.defaultModules ++ [ ../../modules ];

  services.garuda-arch-mirror = {
    enable = true;
    upstreamUrl = "rsync://mirror.23m.com/archlinux/";
    lastupdateUrl = "https://mirror.23m.com/archlinux/lastupdate";
    tls = false;
    rcloneConfig = config.sops.secrets."cloudflare/r2_rclone".path;
    rcloneDest = "r2:/mirror/arch";
  };

  sops.secrets = {
    "cloudflare/r2_rclone" = { };
  };

  system.stateVersion = "25.05";
}
