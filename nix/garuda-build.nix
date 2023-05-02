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

  # Redumentary mailserver configuration to test the mailserver module
  # garudalinux.* domains are going to be added here soonish
  mailserver = {
    enable = true;
    fqdn = "mail.dr460nf1r3.tech";
    domains = [ "dr460nf1r3.tech" ];

    dmarcReporting = {
      domain = "dr460nf1r3.tech";
      enable = true;
      organizationName = "Garuda Linux"; 
    };

    monitoring = {
      alertAddress = "team@garudalinux.org";
      enable = true;
    };

    borgbackup.enable = true;

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "nico@dr460nf1r3.tech" = {
        hashedPasswordFile = "/var/garuda/secrets/pass/nico";
        aliases = [ "postmaster@dr460nf1r3.tech" ];
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;
  };

  system.stateVersion = "22.05";
}
