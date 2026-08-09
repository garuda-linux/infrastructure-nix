{ ... }:
{
  imports = [
    ./arch-mirror.nix
    ./cloudflared.nix
    ./compose-runner/compose-runner.nix
    ./iso.nix
    ./monitoring/monitoring.nix
    ./rclone.nix
  ];
}
