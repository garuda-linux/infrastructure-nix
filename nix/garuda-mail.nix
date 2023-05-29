{ config
, lib
, ...
}: {
  imports = [
    ./garuda/garuda.nix
    ./hardware-configuration.nix
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

  # NixOS Mailserver
  mailserver = {
    borgbackup = {
      enable = true;
      compression.method = "zstd";
    };
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
        aliases = [ "root@garudalinux.org" "webmaster@garudalinux.org" "admin@garudalinux.org" ];
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
        aliases = [ "dr460nf1r3@chaotic.cx" "root@chaotic.cx" "webmaster@chaotic.cx" ];
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

  # Nginx host for Rspamd UI
  services.nginx = {
    enable = true;
    virtualHosts.rspamd = {
      forceSSL = true;
      enableACME = true;
      basicAuthFile = "/var/garuda/secrets/mail/rspamd";
      serverName = "rspamd.garudalinux.net";
      locations = {
        "/" = {
          proxyPass = "http://unix:/run/rspamd/worker-controller.sock:/";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  system.stateVersion = "22.05";
}
