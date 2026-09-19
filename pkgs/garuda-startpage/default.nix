{
  pkgs,
  lib,
  ...
}:
let
  rev = "e4192e76e4914f4a8259dcfe8694dcb7e0e15107"; # main
  srcHash = "sha256-NoPqja2ljWnUNiYgOgmTcS9hf1u1Ie7zEYh0GIkdFaQ=";
  src = pkgs.fetchFromGitLab {
    owner = "garuda-linux/website";
    repo = "startpage-v2";
    inherit rev;
    hash = srcHash;
  };
in
pkgs.callPackage ../mk-pnpm-site.nix {
  inherit pkgs src;
  pname = "garuda-startpage";
  version = "0-unstable-${lib.substring 0 7 rev}";
  pnpmDepsHash = "sha256-7G9jbnEQa6ns+yu+iU5w4wyZaCYBed7gbbbSUg9GsBA=";
  installPath = "./dist/startpage-v3/browser";
  nxCommands = [ "build" ];
}
