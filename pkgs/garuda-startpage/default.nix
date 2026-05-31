{
  pkgs,
  src,
}:
let
  # Run Nx command with fake TTY to avoid panic
  # https://github.com/nrwl/nx/issues/22445
  nx = pkgs.writeScript "nx-wrapper" ''
    exec ${pkgs.faketty}/bin/faketty nx "$@"
  '';
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "garuda-startpage";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = with pkgs; [
    nodejs_24
    pnpm_10.configHook
  ];
  pnpmDeps = pkgs.pnpm_10.fetchDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 1;
    hash = "sha256-pmMxZ9Xc389eWrdLu4hShfs+XIuYraks3NCfxXtBSY0=";
  };
  buildPhase = ''
    export PATH=$(pnpm bin):$PATH
    ${nx} build
  '';
  installPhase = ''
    cp -r ./dist/startpage-v3/browser $out
  '';
})
