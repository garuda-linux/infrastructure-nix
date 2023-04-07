{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.services.garuda-rclone;
  submoduleOptions = {
    options = {
      startAt = mkOption {
        type = types.str;
        default = "hourly";
      };
      config = mkOption {
        type = types.path;
        default = "/root/.config/rclone/rclone.conf";
      };
      extraConfig = mkOption {
        type = types.attrs;
        default = { };
      };
      args = mkOption {
        type = types.str;
        default = "";
      };
      src = mkOption { type = types.str; };
      dest = mkOption { type = types.str; };
    };
  };
in
{
  options.services.garuda-rclone = mkOption {
    type = types.attrsOf (types.submodule submoduleOptions);
    default = { };
  };

  config = {
    systemd.services = mapAttrs'
      (name: value:
        nameValuePair ("garuda-rclone-" + name) (lib.mkMerge [
          {
            description = ''Garuda rclone "${name}" routine'';
            startAt = value.startAt;
            serviceConfig = {
              ExecStart = "${pkgs.rclone}/bin/rclone sync --config=\"${value.config}\" \"${value.src}\" \"${value.dest}\" ${value.args}";
            };
          }
          value.extraConfig
        ]))
      cfg;
  };
}
