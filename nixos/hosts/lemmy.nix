{ garuda-lib
, pkgs
, sources
, ...
}: {
  imports = sources.defaultModules ++ [ ../modules ];

  # Our Lemmy instance
  services.lemmy = {
    database.uri = "postgresql://lemmy:${garuda-lib.secrets.lemmy.database}@10.0.5.50/lemmy";
    nginx.enable = true;
    enable = true;
    settings = {
      hostname = "lemmy.garudalinux.org";
      email = {
        smtp_server = "mail.garudalinux.net:587";
        smtp_login = "noreply@garudalinux.org";
        inherit (garuda-lib.secrets.lemmy) smtp_password;
        smtp_from_address = "noreply@garudalinux.org";
        tls_type = "starttls";
      };
    };
  };

  # Force newest version due to Nixpkgs having dropped 0.3.X.
  # Manual migration from 0.3.X -> 0.4.X -> 0.5.X has been performed.
  # https://github.com/NixOS/nixpkgs/pull/336077
  services.pict-rs.package = pkgs.pict-rs;

  system.stateVersion = "23.05";
}
