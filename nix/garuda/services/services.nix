{ ... }: {
  imports = [
    ./iso.nix
    ./meshagent.nix
    ./cloudflared.nix
    ./monitoring/monitoring.nix
    ./chaotic/chaotic.nix
  ];
}
