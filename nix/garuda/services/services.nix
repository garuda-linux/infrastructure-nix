{ ... }: {
  imports = [
    ./iso.nix
    ./meshagent.nix
    ./monitoring/monitoring.nix
    ./chaotic/chaotic.nix
  ];
}
