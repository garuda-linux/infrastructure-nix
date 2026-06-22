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
  pname = "garuda-website";
  version = "1.0.0";

  inherit src;

  nativeBuildInputs = with pkgs; [
    nodejs_24
    pnpm_11
    pnpmConfigHook
  ];
  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 3;
    hash = "sha256-ma8gseJgBzCa+zXWrLZFyBRuOpHUCwQVZ1DgkeGqMRY=";
  };
  buildPhase = ''
    export PATH=$(pnpm bin):$PATH
    ${nx} build && ${nx} transloco:optimize
  '';
  installPhase = ''
    cp -r ./dist/website/browser $out
  '';
})
