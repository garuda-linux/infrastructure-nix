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
      certs."dr460nf1r3.org" = {
        extraDomainNames = [ "*.dr460nf1r3.org" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = garuda-lib.secrets.cloudflare_key;
      };
      certs."chaotic.cx" = {
        extraDomainNames = [ "*.chaotic.cx" ];
        dnsProvider = "cloudflare";
        dnsPropagationCheck = true;
        credentialsFile = garuda-lib.secrets.cloudflare_key;
      };
    };
  };
}
