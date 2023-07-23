{ ... }: {
  imports = [
    ./chaotic/chaotic.nix
    ./cloudflared.nix
    ./docker-compose-runner/docker-compose-runner.nix
    ./iso.nix
    ./meshagent.nix
    ./monitoring/monitoring.nix
    ./rclone.nix
  ];
}
