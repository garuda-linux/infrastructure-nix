{
  pkgs,
  lib,
  ...
}:
let
  rev = "0748dd565e9e4d015b24d108887ae15459c4d2e6"; # main
  srcHash = "sha256-nCH46nTSRm++a5zcSS2R6zyVdrO5N77OZaweDlNTeVE=";
  src = pkgs.fetchFromGitLab {
    owner = "garuda-linux/website";
    repo = "website-catppuccin";
    inherit rev;
    hash = srcHash;
  };
in
pkgs.callPackage ../mk-pnpm-site.nix {
  inherit pkgs src;
  pname = "garuda-website";
  version = "0-unstable-${lib.substring 0 7 rev}";
  pnpmDepsHash = "sha256-Ihyz6ODZ0Fh3qdnYMUJRLBE6cy5xXYG55VyIIU3+yAc=";
  installPath = "./dist/website/browser";
  nxCommands = [
    "build"
    "transloco:optimize"
  ];
}
