{
  config,
  lib,
  garuda-lib,
  ...
}:
with lib;
let
  certDefinitions = {
    "garudalinux.org" = {
      extraDomainNames = [
        "*.garudalinux.org"
        "iso.builds.garudalinux.org"
      ];
    };
    "garudalinux.net" = {
      extraDomainNames = [
        "*.garudalinux.net"
      ];
    };
    # The apex challenge name _acme-challenge.chaotic.cx is delegated via
    # CNAME to flydns.net for the Fly app serving the apex, so lego would
    # follow it and look for the flydns.net zone in the Cloudflare account.
    # Therefore we can't have a wildcard cert.
    "backend.chaotic.cx" = { };
  };

  # Only issue certificates this host actually references, so a host never
  # requests challenges for domains it does not serve.
  referencedCerts = lib.unique (
    lib.filter (name: name != null) (
      lib.mapAttrsToList (_: vhost: vhost.useACMEHost or null) config.services.nginx.virtualHosts
      ++ lib.optional config.mailserver.enable config.mailserver.x509.useACMEHost
    )
  );
in
{
  config = mkIf (config.services.nginx.enable && !garuda-lib.behind_proxy) {
    security.acme = {
      acceptTerms = true;
      defaults = {
        group = "nginx";
        email = "team@garudalinux.org";
      };
      certs = lib.genAttrs referencedCerts (
        name:
        certDefinitions.${name}
        // {
          dnsProvider = "cloudflare";
          dnsPropagationCheck = true;
          environmentFile = config.sops.secrets."cloudflare/api_keys".path;
        }
      );
    };

    sops.secrets."cloudflare/api_keys" = { };
  };
}
