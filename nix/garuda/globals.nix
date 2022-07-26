{ config, lib, pkgs, ... }:
with lib;
let
  xslt_style = ./static/style.xslt;
in {
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { xslt_style = xslt_style; };
  };
  config._module.args.garuda-lib = config.garuda-lib;
}
