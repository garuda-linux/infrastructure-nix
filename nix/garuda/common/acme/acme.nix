{ pkgs, config, lib, ... }:
with lib; {
  config = mkIf config.services.nginx.enable {
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
        credentialsFile = ./cloudflare_key;
      };
    };
  };
}
