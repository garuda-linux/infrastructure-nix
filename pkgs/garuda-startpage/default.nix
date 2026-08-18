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
    pnpm_11
    pnpmConfigHook
  ];
  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-7G9jbnEQa6ns+yu+iU5w4wyZaCYBed7gbbbSUg9GsBA=";
  };
  buildPhase = ''
    export PATH=$(pnpm bin):$PATH
    ${nx} build
  '';
  installPhase = ''
    cp -r ./dist/startpage-v3/browser $out
  '';
})
