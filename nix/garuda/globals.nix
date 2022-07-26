{ config, lib, pkgs, ... }:
with lib;
let
  xslt_style = pkgs.runCommand "xslt_style-build" { } ''cp "${./static/style.xslt}" "$out"'';
in {
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { xslt_style = xslt_style; };
  };
  config._module.args.garuda-lib = config.garuda-lib;
}
