{
  config,
  lib,
  pkgs,
  sources,
  garuda-lib,
  ...
}:
let
  # https://git.kempkens.io/daniel/dotfiles/src/branch/master/system/nixos/mastodon.nix
  pkg-base = pkgs.mastodon;
  pkg-mastodon = pkg-base.overrideAttrs (_: {
    mastodonModules = pkg-base.mastodonModules.overrideAttrs (
      oldMods:
      let
        tangerine-ui = pkgs.fetchFromGitHub {
          owner = "nileane";
          repo = "TangerineUI-for-Mastodon";
          rev = "v2.3";
          hash = "sha256-Yl5UOjcp0Q3WpiLgfjQFVVEQs4WlVUSBCS7kuO+39wQ=";
        };
      in
      {
        pname = "${oldMods.pname}+themes";

        postPatch = ''
          styleDir=$PWD/app/javascript/styles

          cp -r ${tangerine-ui}/mastodon/app/javascript/styles/* $styleDir

          echo "tangerineui: styles/tangerineui.scss" >>$PWD/config/themes.yml
          echo "tangerineui-purple: styles/tangerineui-purple.scss" >>$PWD/config/themes.yml
          echo "tangerineui-cherry: styles/tangerineui-cherry.scss" >>$PWD/config/themes.yml
          echo "tangerineui-lagoon: styles/tangerineui-lagoon.scss" >>$PWD/config/themes.yml
        '';
      }
    );

    nativeBuildInputs = [ pkgs.yq-go ];

    postBuild = ''
      # Make theme available
      echo "tangerineui: styles/tangerineui.scss" >>$PWD/config/themes.yml
      echo "tangerineui-purple: styles/tangerineui-purple.scss" >>$PWD/config/themes.yml
      echo "tangerineui-cherry: styles/tangerineui-cherry.scss" >>$PWD/config/themes.yml
      echo "tangerineui-lagoon: styles/tangerineui-lagoon.scss" >>$PWD/config/themes.yml

      yq -i '.en.themes.tangerineui = "Tangerine UI"' $PWD/config/locales/en.yml
      yq -i '.en.themes.tangerineui-purple = "Tangerine UI (Purple)"' $PWD/config/locales/en.yml
      yq -i '.en.themes.tangerineui-cherry = "Tangerine UI (Cherry)"' $PWD/config/locales/en.yml
      yq -i '.en.themes.tangerineui-lagoon = "Tangerine UI (Lagoon)"' $PWD/config/locales/en.yml
    '';
  });
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  # Our Mastodon
  services.mastodon = {
    configureNginx = true;
    database = {
      createLocally = false;
      host = "10.0.5.50";
      name = "mastodon";
      passwordFile = config.sops.secrets."mastodon/db_password".path;
      user = "mastodon";
    };
    enable = true;
    extraConfig = {
      "LOCAL_DOMAIN" = "garudalinux.org";
      "SMTP_DOMAIN" = "social.garudalinux.org";
      "WEB_DOMAIN" = "social.garudalinux.org";
    };
    extraEnvFiles = [ config.sops.secrets."mastodon/env".path ];
    localDomain = "social.garudalinux.org";
    mediaAutoRemove = {
      enable = true;
      startAt = "daily";
      olderThanDays = 14;
    };
    package = pkg-mastodon;
    smtp = {
      authenticate = true;
      fromAddress = "noreply@garudalinux.org";
      host = "mail.garudalinux.net";
      passwordFile = config.sops.secrets."mastodon/smtp_password".path;
      port = 587;
      user = "noreply@garudalinux.org";
    };
    streamingProcesses = 16;
  };

  services.nginx = {
    virtualHosts."social.garudalinux.org" = {
      enableACME = lib.mkForce false;
      useACMEHost = "garudalinux.org";
      extraConfig = ''
        ${garuda-lib.nginxReverseProxySettings}
        real_ip_header X-Real-IP;
        set_real_ip_from 10.0.5.10;
      '';
      locations = {
        "@proxy" = {
          proxyWebsockets = lib.mkForce false;
        };
        "/api/v1/streaming/" = {
          proxyWebsockets = lib.mkForce false;
        };
      };
    };
  };

  sops.secrets = {
    "mastodon/db_password" = { };
    "mastodon/env" = { };
    "mastodon/smtp_password" = { };
  };

  system.stateVersion = "25.05";
}
