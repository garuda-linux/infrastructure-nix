{ config, lib, pkgs, ... }:
with lib;
{
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = {
      xslt_style = ./static/style.xslt;
      cloudflare_key = ./static/cloudflare_key;
      meshagent_msh = ./static/meshagent.msh;
    };
  };
  config._module.args.garuda-lib = config.garuda-lib;
}
