{ ... }: {
  # This is on an ESXi, therefore we need the guest tools
  virtualisation.vmware.guest.headless = true;
}
