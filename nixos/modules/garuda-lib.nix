{
  config,
  lib,
  sources,
  pkgs,
  ...
}:
with lib;
let
  secrets = builtins.fromJSON (builtins.readFile ../../secrets/buildtime.json);
  nginxReverseProxySettingsPkg = pkgs.writeText "garuda-proxy-settings.conf" ''
    proxy_redirect          off;
    proxy_connect_timeout   60s;
    proxy_send_timeout      60s;
    proxy_read_timeout      60s;
    proxy_http_version      1.1;
    proxy_set_header        Upgrade $http_upgrade;
    proxy_set_header        Connection $connection_upgrade;
    proxy_set_header        Host $host;
    proxy_set_header        X-Real-IP $remote_addr;
    proxy_set_header        X-Forwarded-For $remote_addr;
    proxy_set_header        X-Forwarded-Proto $scheme;
    proxy_set_header        X-Forwarded-Host $host;
    proxy_set_header        X-Forwarded-Server $host;
  '';
  nginxReverseProxySettings = ''
    include ${nginxReverseProxySettingsPkg};
  '';
  setRealIpFromConfigPkg = pkgs.writeText "garuda-cf-real-ip.conf" (
    lib.concatMapStrings (ip: ''
      set_real_ip_from ${ip};
    '') (lib.strings.splitString "\n" (builtins.readFile sources.cloudflare-ipv4))
    + "\nreal_ip_header CF-Connecting-IP;"
  );
  setRealIpFromConfig = ''
    include ${setRealIpFromConfigPkg};
  '';
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
      inherit setRealIpFromConfig nginxReverseProxySettings;
      minimalContainer = false;
      chaoticUsers = false;
      unifiedUID = false;
      sshkeys = {
        ed25519 = "/etc/ssh/ssh_host_ed25519_key";
        rsa = "/etc/ssh/ssh_host_rsa_key";
      };
      sshkeysContainer = {
        ed25519 = "/etc/ssh.host/ssh_host_ed25519_key";
        rsa = "/etc/ssh.host/ssh_host_rsa_key";
      };
      inherit secrets;
      xslt_style = ./static/style.xslt;
    };
  };
}
