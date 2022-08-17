{ pkgs, config, lib, garuda-lib, ... }:
with lib; {
  config = mkIf (config.services.nginx.enable && !garuda-lib.behind_proxy) {
    security.acme = {
      acceptTerms = true;
      defaults = {
        group = "nginx";
        email = "team@garudalinux.org";
      };
      certs."garudalinux.org" = {
        extraDomainNames = [ "*.garudalinux.org" "iso.builds.garudalinux.org" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = garuda-lib.secrets.cloudflare_key;
      };
    };
  };
}
