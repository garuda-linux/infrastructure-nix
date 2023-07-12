{ lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/containers.nix
  ];

  # Our Mastodon
  services.mastodon = {
    configureNginx = true;
    enable = true;
    localDomain = "social.garudalinux.org";
    smtp = {
      authenticate = true;
      fromAddress = "noreply@garudalinux.org";
      host = "mail.garudalinux.org";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
      port = 587;
      user = "noreply@garudalinux.org";
    };
    extraConfig = {
      "LOCAL_DOMAIN" = "garudalinux.org";
      "SMTP_DOMAIN" = "social.garudalinux.org";
      "WEB_DOMAIN" = "social.garudalinux.org";
    };
    trustedProxy = "10.0.5.90";
  };

  services.nginx.virtualHosts."social.garudalinux.org" = {
    enableACME = lib.mkForce false;
    extraConfig = ''
      set_real_ip_from 10.0.5.50;
      real_ip_header X-Forwarded-For;
    '';
    useACMEHost = "garudalinux.org";
  };

  system.stateVersion = "23.05";
}

