{
  pkgs,
  pname,
  version,
  src,
  pnpmDepsHash,
  installPath,
  nxCommands,
}:
let
  inherit (pkgs) lib;

  # Run Nx command with fake TTY to avoid panic
  # https://github.com/nrwl/nx/issues/22445
  nx = pkgs.writeScript "nx-wrapper" ''
    exec ${pkgs.faketty}/bin/faketty nx "$@"
  '';
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = with pkgs; [
    nodejs_24
    pnpm_11
    pnpmConfigHook
  ];

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = pnpmDepsHash;
  };

  buildPhase = ''
    export PATH=$(pnpm bin):$PATH
    ${lib.concatMapStringsSep " && " (args: "${nx} ${args}") nxCommands}
  '';

  installPhase = ''
    cp -r ${installPath} $out
  '';
})
