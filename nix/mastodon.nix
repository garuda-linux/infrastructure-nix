{ lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ./garuda/garuda.nix
  ];

  # Our Mastodon
  services.mastodon = {
    configureNginx = true;
    database = {
      createLocally = false;
      host = "10.0.5.50";
      name = "mastodon";
      passwordFile = "/var/lib/mastodon/secrets/db-password";
      user = "mastodon";
    };
    enable = true;
    extraConfig = {
      "LOCAL_DOMAIN" = "garudalinux.org";
      "SMTP_DOMAIN" = "social.garudalinux.org";
      "WEB_DOMAIN" = "social.garudalinux.org";
    };
    localDomain = "social.garudalinux.org";
    mediaAutoRemove.enable = false;
    smtp = {
      authenticate = true;
      fromAddress = "noreply@garudalinux.org";
      host = "mail.garudalinux.org";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
      port = 587;
      user = "noreply@garudalinux.org";
    };
    trustedProxy = "10.0.5.10";
  };

  # Run daily synapse state compressor on Matrix database
  systemd.services.mastodon-cleanup = {
    description = "Run daily cleanup of statuses and media of Mastodon";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        set -e
        ${pkgs.mastodon}/bin/mastodon-tootctl media remove --days=7
        ${pkgs.mastodon}/bin/mastodon-tootctl statuses remove --days=7
      '';
      Restart = "on-failure";
      RestartSec = "30";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.mastodon-cleanup = {
    description = "Run daily cleanup of statuses and media of Mastodon";
    timerConfig.OnCalendar = [ "daily" ];
    wantedBy = [ "timers.target" ];
  };

  services.nginx.virtualHosts."social.garudalinux.org" = {
    enableACME = lib.mkForce false;
    extraConfig = ''
      set_real_ip_from 10.0.5.10;
      real_ip_header X-Forwarded-For;
    '';
    useACMEHost = "garudalinux.org";
  };

  system.stateVersion = "23.05";
}

