{
  config,
  garuda-lib,
  lib,
  pkgs,
  sources,
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
          rev = "v2.4.3";
          hash = "sha256-OThT3fp676RMfYY3ehzM4DnAlJOqdPoYIHpoBbN/RHQ=";
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

  # This container is just for compose stuff
  garuda.services.compose-runner.mastodon = {
    source = ../../../compose/mastodon;
  };

  # Our Mastodon
  services.mastodon = {
    configureNginx = true;
    database = {
      createLocally = false;
      host = "10.0.5.20";
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
      olderThanDays = 7;
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
    redis = {
      createLocally = false;
      enableUnixSocket = false;
      host = "localhost";
      port = 6379;
    };
  };

  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  services.nginx = {
    recommendedProxySettings = lib.mkForce false;
    virtualHosts."social.garudalinux.org" = {
      enableACME = lib.mkForce false;
      forceSSL = lib.mkForce false;
      extraConfig = ''
        real_ip_header          X-Real-IP;
        set_real_ip_from        10.0.5.10;
        proxy_redirect          off;
        proxy_connect_timeout   60s;
        proxy_send_timeout      60s;
        proxy_read_timeout      60s;
        proxy_http_version      1.1;
        proxy_set_header        Upgrade $http_upgrade;
        proxy_set_header        Connection $connection_upgrade;
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $remote_addr;
        # I'm a filthy liar
        proxy_set_header        X-Forwarded-Proto https;
        proxy_set_header        X-Forwarded-Host $http_x_forwarded_host;
        proxy_set_header        X-Forwarded-Server $http_x_forwarded_server;
      '';
      locations = {
        "@proxy" = {
          proxyWebsockets = lib.mkForce false;
          extraConfig = ''
            real_ip_header          X-Real-IP;
            set_real_ip_from        10.0.5.10;
            proxy_redirect          off;
            proxy_connect_timeout   60s;
            proxy_send_timeout      60s;
            proxy_read_timeout      60s;
            proxy_http_version      1.1;
            proxy_set_header        Upgrade $http_upgrade;
            proxy_set_header        Connection $connection_upgrade;
            proxy_set_header        Host $host;
            proxy_set_header        X-Real-IP $remote_addr;
            proxy_set_header        X-Forwarded-For $remote_addr;
            # I'm a filthy liar
            proxy_set_header        X-Forwarded-Proto https;
            proxy_set_header        X-Forwarded-Host $http_x_forwarded_host;
            proxy_set_header        X-Forwarded-Server $http_x_forwarded_server;
          '';
        };
        "/api/v1/streaming/" = {
          proxyWebsockets = lib.mkForce false;
        };
      };
    };
  };

  sops.secrets = {
    "mastodon/db_password" = {
      owner = "mastodon";
      group = "mastodon";
    };
    "mastodon/env" = {
      owner = "mastodon";
      group = "mastodon";
    };
    "mastodon/smtp_password" = {
      owner = "mastodon";
      group = "mastodon";
    };
  };

  system.stateVersion = "25.05";
}
