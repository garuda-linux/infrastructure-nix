{
  config,
  lib,
  pkgs,
  sources,
  ...
}:
let
  authres_status = pkgs.roundcubePlugins.roundcubePlugin rec {
    pname = "authres_status";
    version = "0.7.0";
    src = pkgs.fetchzip {
      url = "https://github.com/pimlie/authres_status/archive/refs/tags/${version}.zip";
      hash = "sha256-+rnHc2vJC4ozRdcHAYg1J5rIWe4k/yTgD5xYr9NA/Hg=";
    };
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  # NixOS Mailserver
  mailserver = {
    x509.useACMEHost = "garudalinux.net";
    dmarcReporting.enable = true;
    domains = [
      "garudalinux.org"
      "dr460nf1r3.org"
      "chaotic.cx"
    ];
    enable = true;
    fqdn = "mail.garudalinux.net";
    fullTextSearch = {
      enable = true;
      enforced = "body";
      memoryLimit = 512;
    };
    # To create the password hashes, use nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
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
      "naman@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/namanatgl".path;
      };
      "noreply@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/noreplyatgl".path;
      };
      "rohit@garudalinux.org" = {
        hashedPasswordFile = config.sops.secrets."mail/rohitatgl".path;
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
      # dr460nf1r3.org
      "noreply@dr460nf1r3.org" = {
        hashedPasswordFile = config.sops.secrets."mail/noreplyatdf".path;
      };
      "test@dr460nf1r3.org" = {
        hashedPasswordFile = config.sops.secrets."mail/testatdf".path;
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
    # We do it via UptimeKuma, and since we don't enable NAT reflection in this server, this
    # shuts down the services.
    monitoring.enable = false;
    systemDomain = "garudalinux.org";
    systemName = "Garuda Linux";
    # SMTP on port 587 is deprecated and disabled by default
    # Explicitly disable it to discourage misconfiguration
    enableSubmission = false;
  };

  # Fix dovecot errors caused by failed scudo allocations
  environment.memoryAllocator.provider = lib.mkForce "libc";

  # Set up push notifications
  services.dovecot2.mailPlugins.globally.enable = [
    "notify"
    "push_notification"
  ];

  # Postmaster alias
  services.postfix.postmasterAlias = "nico@dr460nf1r3.org";

  # Web UI
  services.roundcube = {
    enable = true;
    # this is the url of the vhost, not necessarily the same as the fqdn of
    # the mailserver
    hostName = "mail.garudalinux.net";
    extraConfig = ''
      $config['imap_host'] = "ssl://127.0.0.1";
      $config['imap_conn_options'] = array(
        'ssl' => array(
          'verify_peer' => false,
          'verify_peer_name' => false,
        ),
      );
      $config['smtp_host'] = "ssl://127.0.0.1";
      $config['smtp_conn_options'] = array(
        'ssl' => array(
          'verify_peer' => false,
          'verify_peer_name' => false,
        ),
      );
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

  # Secrets
  sops.secrets = {
    "backup/repo_key" = { };
    "backup/ssh_aerialis" = { };
    "mail/a0xzatchaotic" = { };
    "mail/cloudatgl" = { };
    "mail/complaintsatgl" = { };
    "mail/dr460nf1r3atchaotic" = { };
    "mail/dr460nf1r3atgl" = { };
    "mail/filoatgl" = { };
    "mail/gitlabatgl" = { };
    "mail/hatchaotic" = { };
    "mail/mastodonatgl" = { };
    "mail/namanatgl" = { };
    "mail/noreplyatdf" = { };
    "mail/noreplyatgl" = { };
    "mail/rohitatgl" = { };
    "mail/securityatgl" = { };
    "mail/sgsatgl" = { };
    "mail/spam-reportsatgl" = { };
    "mail/teamatgl" = { };
    "mail/testatdf" = { };
    "mail/tneatgl" = { };
    "mail/wilburatchaotic" = { };
    "mail/yorperatgl" = { };
  };

  system.stateVersion = "22.05";

  # https://nixos-mailserver.readthedocs.io/en/latest/migrations.html
  mailserver.stateVersion = 3;
}
