{ ... }:
{
  imports = [
    ./arch-mirror.nix
    ./backup.nix
    ./cloudflared.nix
    ./compose-runner/compose-runner.nix
    ./gitlab-runner.nix
    ./iso.nix
    ./mk.nix
    ./monitoring
    ./rclone.nix
  ];
}
