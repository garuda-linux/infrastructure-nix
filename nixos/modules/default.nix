{ ... }:
{
  imports = [
    ../services/services.nix
    ./acme.nix
    ./common.nix
    ./garuda-lib.nix
    ./hardening.nix
    ./motd.nix
    ./nginx.nix
    ./nspawn-containers.nix
    ./tailscale.nix
    ./users.nix
  ];
}
