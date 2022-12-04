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
        cloudflare_key = "/var/garuda/secrets/cloudflare_key";
        meshagent_msh = "/var/garuda/secrets/meshagent.msh";
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
          esxi-web.cred = "/var/garuda/secrets/cloudflared/esxi-web.json";
          garuda-build.cred =
            "/var/garuda/secrets/cloudflared/garuda-build.json";
          monitor-dragon.cred =
            "/var/garuda/secrets/cloudflared/monitor-dragon.json";
          chaotic-dragon.cred =
            "/var/garuda/secrets/cloudflared/chaotic-dragon.json";
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
            private = "/var/garuda/secrets/buildiso_sshkey";
          };
        };
      };
    };
  };
}
