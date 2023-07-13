{ config
, lib
, sources
, ...
}:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ./secrets/secrets.json);
  setRealIpFromConfig = lib.concatMapStrings
    (ip: ''
      set_real_ip_from ${ip};
    '')
    (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4));
in
{
  options.garuda-lib = mkOption {
    type = types.attrs;
    default = { };
  };
  config = {
    _module.args.garuda-lib = config.garuda-lib;
    # Defaults
    garuda-lib = {
      behind_proxy = false;
      inherit setRealIpFromConfig;
      minimalContainer = false;
      unifiedUID = false;
      secrets = recursiveUpdate secrets {
        cachix = "/var/garuda/secrets/cachix";
        github-runner-token = "/var/garuda/secrets/github-runner-token";
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
          all-in-one = "/var/garuda/secrets/docker-compose/all-in-one.env";
          runner = "/var/garuda/secrets/docker-compose/runner.env";
        };
        mail = {
          actionsatcx = "/var/garuda/secrets/mail/actionsatcx";
          cloudatgl = "/var/garuda/secrets/mail/cloudatgl";
          complaintsatgl = "/var/garuda/secrets/mail/complaintsatgl";
          dr460nf1r3atgl = "/var/garuda/secrets/mail/dr460nf1r3atgl";
          filoatgl = "/var/garuda/secrets/mail/filoatgl";
          gitlabatgl = "/var/garuda/secrets/mail/gitlabatgl";
          mastodonatgl = "/var/garuda/secrets/mail/mastodonatgl";
          namanatgl = "/var/garuda/secrets/mail/namanatgl";
          nicoatcx = "/var/garuda/secrets/mail/nicoatcx";
          noreplyatgl = "/var/garuda/secrets/mail/noreplyatgl";
          rohitatgl = "/var/garuda/secrets/mail/rohitatgl";
          securityatgl = "/var/garuda/secrets/mail/securityatgl";
          sgsatgl = "/var/garuda/secrets/mail/sgsatgl";
          spam-reportsatgl = "/var/garuda/secrets/mail/spam-reportsatgl";
          teamatgl = "/var/garuda/secrets/mail/teamatgl";
          tneatgl = "/var/garuda/secrets/mail/tnegl";
          yorperatgl = "/var/garuda/secrets/mail/yorperatgl";
        };
        ssh = {
          team = {
            private = "/var/garuda/secrets/team_sshkey";
          };
        };
      };
      xslt_style = ./static/style.xslt;
    };
  };
}
