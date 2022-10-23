{ ... }: {
  # This is on an ESXi, therefore we need the guest tools
  virtualisation.vmware.guest = {
    enable = true;
    headless = true;
  };
}
