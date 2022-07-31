{ config, lib, pkgs, ... }:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ./secrets/secrets.json);
in {
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = {
      xslt_style = ./static/style.xslt;
      cloudflare_key = ./secrets/cloudflare_key;
      meshagent_msh = ./secrets/meshagent.msh;
      zerotier_network = secrets.zerotier_network;
      telegram = secrets.telegram;
      netdata = secrets.netdata;
      datadog = secrets.datadog;
    };
  };
  config._module.args.garuda-lib = config.garuda-lib;
}
