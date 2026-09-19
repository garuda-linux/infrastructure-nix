{
  config,
  garuda-lib,
  lib,
  pkgs,
  sources,
  ...
}:
let
  mon = garuda-lib.monitoring;

  authres_status = pkgs.roundcubePlugins.roundcubePlugin rec {
    pname = "authres_status";
    version = "0.7.1";
    src = pkgs.fetchzip {
      url = "https://github.com/pimlie/authres_status/archive/refs/tags/${version}.zip";
      hash = "sha256-vQGllx3NzVkjQdnIosvQtI3iQ02HrGIF7sSL7G2E5c4=";
    };
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda = garuda-lib.mkMonitoring {
    host = "aerialis";
    units = [
      "dovecot2.service"
      "nginx.service"
      "postfix.service"
      "rspamd.service"
    ];
    exporters = [ "postfixExporter" ];
  };

  # NixOS Mailserver
  mailserver = {
    x509.useACMEHost = "garudalinux.net";
    dmarcReporting.enable = true;
    domains = [
      "garudalinux.org"
      "chaotic.cx"
    ];
    enable = true;
    enableManageSieve = true;
    fqdn = "mail.garudalinux.net";
    fullTextSearch = {
      enable = true;
      memoryLimit = 512;
    };

    # To create the password hashes, use nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    accounts = {
      # garudalinux.org
      "cloud@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/cloudatgl".path;
        sendOnly = true;
      };
      "complaints@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/complaintsatgl".path;
      };
      "dr460nf1r3@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/dr460nf1r3atgl".path;
      };
      "filo@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/filoatgl".path;
      };
      "gitlab@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/gitlabatgl".path;
      };
      "mastodon@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/mastodonatgl".path;
        sendOnly = true;
      };
      "noreply@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/noreplyatgl".path;
      };
      "security@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/securityatgl".path;
      };
      "sgs@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/sgsatgl".path;
      };
      "spam-reports@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/spam-reportsatgl".path;
      };
      "team@garudalinux.org" = {
        aliases = [
          "admin@garudalinux.org"
          "ci@garudalinux.org"
          "root@garudalinux.org"
          "webmaster@garudalinux.org"
        ];
        hashedPasswordFile = config.sops.secrets."mail/teamatgl".path;
      };
      "tne@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/tneatgl".path;
      };
      "yorper@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/yorperatgl".path;
      };
      # chaotic.cx
      "a0xz@chaotic.cx" = {
        hashedPasswordFile = config.sops.secrets."mail/a0xzatchaotic".path;
      };
      "dr460nf1r3@chaotic.cx" = {
        aliases = [
          "actions@chaotic.cx"
          "admin@chaotic.cx"
          "root@chaotic.cx"
          "temeraire@chaotic.cx"
          "webmaster@chaotic.cx"
        ];
        hashedPasswordFile = config.sops.secrets."mail/dr460nf1r3atchaotic".path;
      };
      "h@chaotic.cx" = {
        hashedPasswordFile = config.sops.secrets."mail/hatchaotic".path;
      };
      "wilbur@chaotic.cx" = {
        hashedPasswordFile = config.sops.secrets."mail/wilburatchaotic".path;
      };
    };
    forwards = {
      "any_@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.pedrohlc ];
      "coc@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.pedrohlc ];
      "coffee-machine@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.pedrohlc ];
      "islandc0der@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.islandc0der ];
      "no-reply@chaotic.cx" = [ ];
      "noreply@chaotic.cx" = [ ];
      "pedrohlc@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.pedrohlc ];
      "pgc@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.pedrohlc ];
      "xstefen@chaotic.cx" = [ config.garuda-lib.secrets.mail.forwards.xstefen ];
    };
    indexDir = "/var/lib/dovecot/indices";
    systemDomain = "garudalinux.org";
    systemName = "Garuda Linux";
    # SMTP on port 587 is deprecated and disabled by default
    # Explicitly disable it to discourage misconfiguration
    enableSubmission = false;
  };

  # Fix dovecot errors caused by failed scudo allocations
  environment.memoryAllocator.provider = lib.mkForce "libc";

  # Set up push notifications
  services.dovecot2.settings = {
    mail_plugins = {
      notify = true;
      push_notification = true;
    };

    "service stats" = {
      "inet_listener http" = {
        port = mon.ports.dovecotMetrics;
      };
    };
    "metric auth_success" = {
      filter = "event=auth_request_finished AND success=yes";
    };
    "metric auth_failure" = {
      filter = "event=auth_request_finished AND success=no";
    };
    "metric imap_command" = {
      filter = "event=imap_command_finished";
      "group_by cmd_name" = { };
      "group_by tagged_reply_state" = { };
    };
    "metric mail_delivery" = {
      filter = "event=mail_delivery_finished";
    };
    "metric push_notification" = {
      filter = "event=push_notification_finished";
    };
  };

  networking.firewall.interfaces."eth0".allowedTCPPorts = [ mon.ports.dovecotMetrics ];

  # Postmaster alias
  services.postfix.postmasterAlias = "root@garudalinux.org";

  # Web UI
  services.roundcube = {
    enable = true;
    # this is the url of the vhost, not necessarily the same as the fqdn of
    # the mailserver
    hostName = "mail.garudalinux.net";
    extraConfig = ''
      $config['default_host'] = "ssl://mail.garudalinux.net";
      $config['smtp_host'] = "ssl://mail.garudalinux.net";
      $config['managesieve_host'] = "tls://mail.garudalinux.net:4190";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
    package = pkgs.roundcube.withPlugins (plugins: [
      authres_status
      plugins.carddav
      plugins.contextmenu
      plugins.custom_from
      plugins.persistent_login
      plugins.thunderbird_labels
    ]);
    plugins = [
      "attachment_reminder" # Roundcube internal plugin
      "authres_status"
      "carddav"
      "contextmenu"
      "custom_from"
      "managesieve" # Roundcube internal plugin
      "newmail_notifier" # Roundcube internal plugin
      "persistent_login"
      "thunderbird_labels"
      "zipdownload" # Roundcube internal plugin
    ];
  };
  services.nginx.virtualHosts."mail.garudalinux.net" = {
    forceSSL = lib.mkForce false;
  };

  sops.secrets = garuda-lib.mkSecrets [
    "backup/repo_key"
    "backup/ssh_aerialis"
    "mail/a0xzatchaotic"
    "mail/cloudatgl"
    "mail/complaintsatgl"
    "mail/dr460nf1r3atchaotic"
    "mail/dr460nf1r3atgl"
    "mail/filoatgl"
    "mail/gitlabatgl"
    "mail/hatchaotic"
    "mail/mastodonatgl"
    "mail/noreplyatgl"
    "mail/securityatgl"
    "mail/sgsatgl"
    "mail/spam-reportsatgl"
    "mail/teamatgl"
    "mail/tneatgl"
    "mail/wilburatchaotic"
    "mail/yorperatgl"
  ];

  system.stateVersion = "22.05";

  # https://nixos-mailserver.readthedocs.io/en/latest/migrations.html
  mailserver.stateVersion = 5;
}
