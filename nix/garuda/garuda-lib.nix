{ config, lib, pkgs, ... }:
with lib;
let secrets = builtins.fromJSON (builtins.readFile ./secrets/secrets.json);
in {
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { };
  };
  config = {
    _module.args.garuda-lib = config.garuda-lib;
    # Defaults
    garuda-lib = {
      xslt_style = ./static/style.xslt;
      behind_proxy = false;
      secrets = recursiveUpdate secrets {
        cloudflare_key = "/var/garuda/secrets/cloudflare_key";
        meshagent_msh = "/var/garuda/secrets/meshagent.msh";
        buildiso_sshkey = "/var/garuda/secrets/buildiso_sshkey";
        syncthing = {
          esxi = {
            key = "/var/garuda/secrets/syncthing/esxi-key.pem";
            cert = "/var/garuda/secrets/syncthing/esxi-cert.pem";
          };
          garuda-build = {
            key = "/var/garuda/secrets/syncthing/garuda-build-key.pem";
            cert = "/var/garuda/secrets/syncthing/garuda-build-cert.pem";
          };
        };
        cloudflared = {
          esxi-repo.cred = "/var/garuda/secrets/cloudflared/esxi-repo.json";
          garuda-build.cred =
            "/var/garuda/secrets/cloudflared/garuda-build.json";
        };
        docker-compose = {
          web-dragon = "/var/garuda/secrets/docker-compose/web-dragon.env";
        };
      };
    };
  };
}
