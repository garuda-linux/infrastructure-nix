{ config
, lib
, pkgs
, ...
}:
let
  authres_status = pkgs.roundcubePlugins.roundcubePlugin rec {
    pname = "authres_status";
    version = "0.6.3";
    src = pkgs.fetchzip {
      url = "https://github.com/pimlie/authres_status/archive/refs/tags/${version}.zip";
      hash = "sha256-WebJiN0vRkvc0AKvMm+inK3FY37R04q3y/0rFoiUW6A=";
    };
  };
in
{
  imports = [
    ../modules
    ./garuda-mail/hardware-configuration.nix
  ];

  # Base configuration
  networking.interfaces.ens3.ipv4.addresses = [{
    address = "94.16.112.218";
    prefixLength = 22;
  }];
  networking.hostName = "garuda-mail";
  networking.defaultGateway = "94.16.112.3";

  # GRUB
  boot.loader.grub.devices = [ "/dev/vda" ];

  # Backup configurations to Hetzner storage box
  programs.ssh.macs = [ "hmac-sha2-512" ];
  services.borgbackup.jobs = {
    backupToHetzner = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_garuda-mail -p 23";
      };
      paths = [ config.mailserver.mailDirectory "/var/dkim" ];
      prune.keep = {
        within = "1d";
        daily = 5;
        weekly = 2;
        monthly = 1;
      };
      repo = "u358867@u358867.your-storagebox.de:./garuda-mail";
      startAt = "daily";
    };
  };

  # NixOS Mailserver
  mailserver = {
    certificateScheme = "acme-nginx";
    dmarcReporting = {
      domain = "garudalinux.org";
      enable = true;
      organizationName = "Garuda Linux";
    };
    domains = [ "garudalinux.org" "chaotic.cx" "dr460nf1r3.org" ];
    enable = true;
    enableManageSieve = true;
    # Forwards (mostly chaotic.cx only)
    forwards =
      {
        "coffee-machine@chaotic.cx" = "root@pedrohlc.com";
        "islandc0der@chaotic.cx" = "jf.mundox@gmail.com";
        "pedrohlc@chaotic.cx" = "root@pedrohlc.com";
        "xstefen@chaotic.cx" = "me@xstefen.dev";
      };
    fqdn = "mail.garudalinux.net";
    fullTextSearch = {
      enable = true;
      enforced = "body";
      indexAttachments = true;
      memoryLimit = 512;
    };
    # To create the password hashes, use nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      # garudalinux.org
      "cloud@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/cloudatgl";
        sendOnly = true;
      };
      "complaints@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/complaintsatgl";
      };
      "dr460nf1r3@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/dr460nf1r3atgl";
      };
      "filo@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/filoatgl";
      };
      "gitlab@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/gitlabatgl";
      };
      "mastodon@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/mastodonatgl";
        sendOnly = true;
      };
      "naman@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/namanatgl";
      };
      "noreply@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/noreplyatgl";
      };
      "rohit@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/rohitatgl";
      };
      "security@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/securityatgl";
      };
      "sgs@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/sgsatgl";
      };
      "spam-reports@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/spam-reportsatgl";
      };
      "team@garudalinux.org" = {
        aliases = [
          "admin@garudalinux.org"
          "ci@garudalinux.org"
          "root@garudalinux.org"
          "webmaster@garudalinux.org"
        ];
        hashedPasswordFile = "/var/garuda/secrets/mail/teamatgl";
      };
      "tne@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/tneatgl";
      };
      "yorper@garudalinux.org" = {
        hashedPasswordFile = "/var/garuda/secrets/mail/yorperatgl";
      };
      # chaotic.cx
      "actions@chaotic.cx" = {
        aliases = [ "temeraire@chaotic.cx" ];
        hashedPasswordFile = "/var/garuda/secrets/mail/actionsatcx";
      };
      "nico@chaotic.cx" = {
        aliases = [
          "dr460nf1r3@chaotic.cx"
          "root@chaotic.cx"
          "webmaster@chaotic.cx"
        ];
        hashedPasswordFile = "/var/garuda/secrets/mail/nicoatcx";
      };
      # dr460nf1r3.org
      "nico@dr460nf1r3.org" = {
        aliases = [ "@dr460nf1r3.org" ];
        catchAll = [ "dr460nf1r3.org" ];
        hashedPasswordFile = "/var/garuda/secrets/mail/nicoatdf";
      };
    };
    indexDir = "/var/lib/dovecot/indices";
    monitoring = {
      alertAddress = "team@garudalinux.org";
      enable = true;
    };
    rebootAfterKernelUpgrade.enable = true;
  };

  # Fix dovecot errors caused by failed scudo allocations
  environment.memoryAllocator.provider = lib.mkForce "libc";

  # Postmaster alias
  services.postfix.postmasterAlias = "nico@dr460nf1r3.org";

  # Web UI
  services.roundcube = {
    enable = true;
    # this is the url of the vhost, not necessarily the same as the fqdn of
    # the mailserver
    hostName = "mail.garudalinux.net";
    extraConfig = ''
      # starttls needed for authentication, so the fqdn required to match
      # the certificate
      $config['smtp_server'] = "tls://${config.mailserver.fqdn}";
      $config['smtp_user'] = "%u";
      $config['smtp_pass'] = "%p";
    '';
    package = pkgs.roundcube.withPlugins (
      plugins: [
        authres_status
        plugins.carddav
        plugins.contextmenu
        plugins.custom_from
        plugins.persistent_login
        plugins.thunderbird_labels
      ]
    );
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

  # At least try to prevent the insane spam of login attempts
  services.openssh.ports = [ 1022 ];

  # This mostly sends annoying notifications because SSH port is non-default
  services.monit.enable = lib.mkForce false;

  system.stateVersion = "22.05";
}
