{ lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

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
      host = "mail.garudalinux.net";
      passwordFile = "/var/lib/mastodon/secrets/smtp-password";
      port = 587;
      user = "noreply@garudalinux.org";
    };
    trustedProxy = "10.0.5.10";
    streamingProcesses = 4;
  };

  # Run daily cleanup of statuses and media of Mastodon
  systemd.services.mastodon-media-cleanup = {
    description = "Run daily cleanup of statuses and media of Mastodon";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        set -e
        /run/current-system/sw/bin/mastodon-tootctl media remove --days=30
        /run/current-system/sw/bin/mastodon-tootctl statuses remove --days=30
      '';
      Path = [ pkgs.mastodon ];
      Restart = "on-failure";
      RestartSec = "30";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.mastodon-media-cleanup = {
    description = "Monthly cleanup of statuses and media of Mastodon";
    timerConfig.OnCalendar = [ "monthly" ];
    wantedBy = [ "timers.target" ];
  };

  # Scan for orphaned media mo
  systemd.services.mastodon-orphan-cleanup = {
    description = "Run weekly cleanup of orphaned media of Mastodon";
    serviceConfig = {
      ExecStart = pkgs.writeShellScript "execstart" ''
        set -e
        /run/current-system/sw/bin/mastodon-tootctl media remove --days=7
        /run/current-system/sw/bin/mastodon-tootctl statuses remove --days=7
      '';
      Path = [ pkgs.mastodon ];
      Restart = "on-failure";
      RestartSec = "30";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.timers.mastodon-orphan-cleanup = {
    description = "Run weekly cleanup of orphaned media of Mastodon";
    timerConfig.OnCalendar = [ "weekly" ];
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

