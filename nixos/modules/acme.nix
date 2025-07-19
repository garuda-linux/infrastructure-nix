{
  config,
  lib,
  garuda-lib,
  ...
}:
with lib;
{
  config = mkIf (config.services.nginx.enable && !garuda-lib.behind_proxy) {
    security.acme = {
      acceptTerms = true;
      defaults = {
        group = "nginx";
        email = "team@garudalinux.org";
      };
      certs = {
        "garudalinux.org" = {
          extraDomainNames = [
            "*.garudalinux.org"
            "iso.builds.garudalinux.org"
          ];
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialsFile = config.sops.secrets."cloudflare/api_keys".path;
        };
        "garudalinux.net" = {
          extraDomainNames = [
            "*.garudalinux.net"
          ];
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          credentialsFile = config.sops.secrets."cloudflare/api_keys".path;
        };
      };
    };

    sops.secrets."cloudflare/api_keys" = { };
  };
}
