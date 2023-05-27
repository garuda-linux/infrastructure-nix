{ ... }: {
  imports = [
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.interfaces.ens18.ipv4.addresses = [{
    address = "216.158.66.108";
    prefixLength = 24;
  }];
  networking.hostName = "garuda-build";
  networking.defaultGateway = "216.158.66.97";

  # NixOS Mailserver
  mailserver = {
    borgbackup = {
      enable = true;
      compression.method = "zstd";
    };
    certificateScheme = 3;
    dkimKeyBits = 2048;
    dmarcReporting = {
      domain = "garudalinux.net";
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
      memoryLimit = 512;
    };
    # To create the password hashes, use nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      # garudalinux.org
      "cloud@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/cloudatgl";
        sendOnly = true;
      };
      "complaints@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/complaintsatgl";
      };
      "dr460nf1r3@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/dr460nf1r3atgl";
      };
      "filo@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/filoatgl";
      };
      "gitlab@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/gitlabatgl";
      };
      "mastodon@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/mastodonatgl";
        sendOnly = true;
      };
      "rohit@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/rohitatgl";
      };
      "security@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/securityatgl";
      };
      "sgs@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/sgsatgl";
      };
      "spam-reports@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/spam-reportsatgl";
      };
      "team@garudalinux.org" = {
        aliases = [ "root@garudalinux.org" "webmaster@garudalinux.org" "admin@garudalinux.org" ];
        hashedmailwordFile = "/var/garuda/secrets/mail/teamatgl";
      };
      "tne@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/tneatgl";
      };
      "yorper@garudalinux.org" = {
        hashedmailwordFile = "/var/garuda/secrets/mail/yorperatgl";
      };
      # chaotic.cx
      "actions@chaotic.cx" = {
        aliases = [ "temeraire@chaotic.cx" ];
        hashedmailwordFile = "/var/garuda/secrets/mail/actionsatcx";
      };
      "nico@chaotic.cx" = {
        aliases = [ "dr460nf1r3@chaotic.cx" "root@chaotic.cx" "webmaster@chaotic.cx" ];
        hashedmailwordFile = "/var/garuda/secrets/mail/nicoatcx";
      };
      # dr460nf1r3.org
      "nico@dr460nf1r3.org" = {
        aliases = [ "@dr460nf1r3.org" ];
        catchAll = [ "dr460nf1r3.org" ];
        hashedmailwordFile = "/var/garuda/secrets/mail/nicoatdf";
      };
    };
    indexDir = "/var/lib/dovecot/indices";
    monitoring = {
      alertAddress = "team@garudalinux.org";
      enable = true;
    };
    rebootAfterKernelUpgrade.enable = true;
  };

  system.stateVersion = "22.05";
}
