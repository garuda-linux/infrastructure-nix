{ ... }: {
  # LXC support
  boot.isContainer = true;
  boot.loader.initScript.enable = true;
  systemd.enableUnifiedCgroupHierarchy = false;
}
