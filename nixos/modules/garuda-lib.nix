{ config
, lib
, sources
, ...
}:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ../secrets/secrets.json);
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
        meshagent_msh = "/var/garuda/secrets/meshagent.msh";
        syncthing = {
          esxi-build = {
            cert = "/var/garuda/secrets/syncthing/esxi-build-cert.pem";
            key = "/var/garuda/secrets/syncthing/esxi-build-key.pem";
          };
        };
        chaotic = {
          interfere_ed25519 = "/var/garuda/secrets/chaotic/interfere_ed25519";
          telegram-send-group = "/var/garuda/secrets/chaotic/telegram-send-group.conf";
          telegram-send-log = "/var/garuda/secrets/chaotic/telegram-send-log.conf";
        };
        cloudflare = {
          cloudflared = {
            esxi-web.cred = "/var/garuda/secrets/cloudflare/esxi-web.json";
            esxi-build.cred =
              "/var/garuda/secrets/cloudflare/esxi-build.json";
          };
          r2 = {
            rclone = "/var/garuda/secrets/cloudflare/rclone.conf";
          };
          apikeys = "/var/garuda/secrets/cloudflare/cloudflare_key";
        };
        docker-compose = {
          all-in-one = "/var/garuda/secrets/docker-compose/all-in-one.env";
          github-runner = "/var/garuda/secrets/docker-compose/github-runner.env";
          proxied = "/var/garuda/secrets/docker-compose/proxied.env";
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
