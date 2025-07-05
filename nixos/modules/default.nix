{ ... }:
{
  imports = [
    ../services
    ./common.nix
    ./create-home.nix
    ./garuda-lib.nix
    ./hardening.nix
    ./motd.nix
    ./nginx.nix
    ./nspawn-containers.nix
    ./tailscale.nix
    ./users.nix
  ];
}
