{
  config,
  garuda-lib,
  sources,
  ...
}:
let
  inherit (garuda-lib.monitoring) aerialisContainers;
  ph = config.sops.placeholder;

  mkConfig = content: {
    inherit content;
    mode = "0444";
    restartUnits = [ "compose-runner-openqa.service" ];
  };
in
{
  imports = sources.defaultModules ++ [ ../../modules ];

  garuda =
    garuda-lib.mkMonitoring {
      host = "aerialis";
      units = [
        "compose-runner-openqa.service"
        "docker.service"
      ];
    }
    // {
      services.compose-runner.openqa = {
        source = ../../../compose/openqa;
        extraFiles = [
          {
            targetFileName = "openqa.ini";
            file = config.sops.templates."openqa.ini".path;
          }
          {
            targetFileName = "database.ini";
            file = config.sops.templates."openqa-database.ini".path;
          }
          {
            targetFileName = "client.conf";
            file = config.sops.templates."openqa-client.conf".path;
          }
        ];
      };
    };

  # Written by different unprivileged users in webui and worker
  systemd.tmpfiles.rules = map (dir: "d /var/lib/openqa-data/${dir} 0777 root root") [
    "factory"
    "factory/iso"
    "factory/hdd"
    "factory/other"
    "factory/repo"
    "factory/tmp"
    "images"
    "pool"
    "testresults"
    "tests"
  ];

  sops.secrets = {
    "openqa/api_key" = { };
    "openqa/api_secret" = { };
    "openqa/db_password" = { };
    "openqa/oauth2_key" = { };
    "openqa/oauth2_secret" = { };
  };

  sops.templates = {
    "openqa.ini" = mkConfig ''
      [global]
      appname = Garuda Linux openQA
      branding = plain
      base_url = https://openqa.garudalinux.org
      download_domains = iso.builds.garudalinux.org
      recognized_referers = gitlab.com

      [auth]
      method = OAuth2

      [oauth2]
      provider = custom
      unique_name = gitlab
      key = ${ph."openqa/oauth2_key"}
      secret = ${ph."openqa/oauth2_secret"}
      authorize_url = https://gitlab.com/oauth/authorize?response_type=code
      token_url = https://gitlab.com/oauth/token
      user_url = https://gitlab.com/api/v4/user
      token_scope = read_user
      token_label = Bearer
      id_from = id
      fullname_from = name
      nickname_from = username
      email_from = email

      [default_group_limits]
      asset_size_limit = 60
      result_storage_duration = 90

      # The gate schedules without a job group
      [no_group_limits]
      result_storage_duration = 90

      # No systemd cleanup timers in the container
      [minion_task_triggers]
      on_job_done = limit_results_and_logs limit_assets

      [misc_limits]
      untracked_assets_storage_duration = 7
    '';

    "openqa-database.ini" = mkConfig ''
      [production]
      dsn = DBI:Pg:dbname=openqa;host=${aerialisContainers.postgres}
      user = openqa
      password = ${ph."openqa/db_password"}
    '';

    # Section = HOST in workers.ini
    "openqa-client.conf" = mkConfig ''
      [webui]
      key = ${ph."openqa/api_key"}
      secret = ${ph."openqa/api_secret"}
    '';
  };

  system.stateVersion = "26.11";
}
