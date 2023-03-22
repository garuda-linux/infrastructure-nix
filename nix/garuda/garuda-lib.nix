{ config, lib, pkgs, sources, ... }:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ./secrets/secrets.json);
  setRealIpFromConfig = lib.concatMapStrings (ip: ''
    set_real_ip_from ${ip};
  '') (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4));
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
      inherit setRealIpFromConfig;
      secrets = recursiveUpdate secrets {
        cachix = "/var/garuda/secrets/cachix";
        meshagent_msh = "/var/garuda/secrets/meshagent.msh";
        syncthing = {
          kde-dragon = {
            key = "/var/garuda/secrets/syncthing/kde-dragon-key.pem";
            cert = "/var/garuda/secrets/syncthing/kde-dragon-cert.pem";
          };
          esxi-build = {
            key = "/var/garuda/secrets/syncthing/esxi-build-key.pem";
            cert = "/var/garuda/secrets/syncthing/esxi-build-cert.pem";
          };
        };
        cloudflare = {
          cloudflared = {
            kde-dragon.cred = "/var/garuda/secrets/cloudflare/kde-dragon.json";
            esxi-web.cred = "/var/garuda/secrets/cloudflare/esxi-web.json";
            esxi-build.cred =
            "/var/garuda/secrets/cloudflare/esxi-build.json";
            monitor-dragon.cred =
              "/var/garuda/secrets/cloudflare/monitor-dragon.json";
            chaotic-dragon.cred =
              "/var/garuda/secrets/cloudflare/chaotic-dragon.json";
          };
          r2 = {
            rclone = "/var/garuda/secrets/cloudflare/rclone.conf";
          };
          apikeys = "/var/garuda/secrets/cloudflare/cloudflare_key";
        };
        docker-compose = {
          esxi-cloud = "/var/garuda/secrets/docker-compose/esxi-cloud.env";
          esxi-web = "/var/garuda/secrets/docker-compose/esxi-web.env";
          esxi-web-two = "/var/garuda/secrets/docker-compose/esxi-web-two.env";
          web-dragon = "/var/garuda/secrets/docker-compose/web-dragon.env";
          oracle-dragon = "/var/garuda/secrets/docker-compose/oracle-dragon.env";
        };
        ssh = {
          team = {
            private = "/var/garuda/secrets/team_sshkey";
          };
        };
      };
    };
  };
}
