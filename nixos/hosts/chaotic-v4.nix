{ config
, garuda-lib
, sources
, pkgs
, ...
}:
{
  imports = sources.defaultModules ++ [ ../modules "${sources.chaotic-portable-builder}/nix/nixos.nix" ];

  # Redis is used to distribute build jobs
  services.redis = {
    vmOverCommit = true;
    servers."chaotic" = {
      bind = null;
      enable = true;
      port = 6379;
      requirePassFile = "/var/garuda/secrets/chaotic/redis";
    };
  };

  # This container is just for docker-compose stuff
  services.docker-compose-runner.chaotic-v4 = {
    envfile = garuda-lib.secrets.docker-compose.chaotic-v4;
    source = ../../docker-compose/chaotic-v4;
  };

  # Lock down chaotic-op group to SCP in landing zone
  services.openssh.extraConfig = ''
    Match Group chaotic-op
      AllowTCPForwarding yes
      AllowAgentForwarding no
      X11Forwarding no
      PermitTunnel no
      ForceCommand internal-sftp
      PermitOpen 127.0.0.1:6379
  '';

  # Our package deploying users
  users.users.package-deployer = {
    isNormalUser = true;
    extraGroups = [ "chaotic-op" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN47/usTQsbmcAuG8CbEkurMDzQJxs+Tf8njI/4iTpKu"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN7W5KtNH5nsjIHBN1zBwEc0BZMhg6HfFurMIJoWf39p"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwGMzxuAXAHc+DHbOlgRo/FShbF/QXrlJzhl2k/WBHB" # u726578@sms.cluster.infra.ufscar.br
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHELhrMFNvxgAYMdzwerszypuvQc3uCFjkR6xCbcQnrcCrueJqTQ4y8WzddwxhRzKbSTQVhPdB5l95IYk7eOtmBmaMp4LAV2osMWDI/x3NyoY5s7YgpW815qNX9Io7VnrFUr0LK7hJ+Uw87nyxGp3zGddPVMUK7PIdJf2GxTxKPryycdLa9QWijfm3YBdN10yBMp6KrfPEnhtmNPMrc3wuBG4+xBoJxNOy0DJdIf2PRwU2CddP0zdDWwlMbGeHGcaJmlAx0u9e1jL8KWB/oyGT1D9q4l+fU8E9nZG+kAFMO1yG25je9bJnYNPMV1gdRT47G3J/B982XYO4G4AiOER0v0M0MN0qWTvIVBG6Vnly81ME91Qao34Lw2QOhZMVFwWz01u8KLLQy/Z2rX7jKyqeUyGXgs5NPmkeJ1vzpSRLXY+5GX5yva8A041Nft7sfKYPFjMsDaxAKVPz7LkKX1dYdiC4c3a/RcCzLKY+Uabjr0QAK4MKwmMW+SNF0QHr9mk= root@Chaotic" # CatBuilder
    ];
  };
  users.groups.chaotic-op = { };

  # Expose raw /proc for podman
  systemd.services.expose-raw-proc = {
    description = "Expose clean /proc for podman";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /tmp/raw_proc
      ${pkgs.mount}/bin/mount --bind /proc /tmp/raw_proc
    '';
  };

  networking.firewall.allowedTCPPorts = [
    config.services.grafana.settings.server.http_port # Grafana
    config.services.redis.servers.chaotic.port # Redis
    config.services.rsyncd.port # Rsync
    8384 # Syncthing web interface
  ];

  # Enable the user accounts of chaotic maintainers
  garuda-lib.chaoticUsers = true;

  # Prometheus for monitoring the metrics exported by chaotic-manager
  services.prometheus = {
    enable = true;
    port = 9090;
    scrapeConfigs = [
      {
        job_name = "chaotic-manager";
        static_configs = [
          {
            targets = [
              "127.0.0.1:3030"
            ];
          }
        ];
      }
    ];
  };

  # Grana for displaying Prometheus data
  services.grafana = {
    enable = true;
    provision = {
      enable = false;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            access = "proxy";
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          }
        ];
      };
    };
    settings = {
      auth.anonymous = "enabled";
      analytics = {
        feedback_links_enabled = false;
        reporting_enabled = false;
      };
      live.allowed_origins = [ "https://grafana.garudalinux.net" "http://10.0.5.10" ]; # Needed to get WS to work
      security = {
        admin_email = "team@garudalinux.org";
        cookie_secure = true;
      };
      server = {
        enable_gzip = true;
        http_addr = "10.0.5.140";
        http_port = 3001;
        protocol = "http";
      };
    };
  };

  # Syncthing setup
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    configDir = config.services.syncthing.dataDir;
    inherit (garuda-lib.secrets.syncthing.esxi-build) cert key;
    overrideFolders = false;
    overrideDevices = false;
    user = "root";
    group = "chaotic-op";
    settings = {
      gui = {
        apikey = "garudalinux";
        insecureSkipHostcheck = true;
        inherit (garuda-lib.secrets.syncthing.esxi-build.credentials) user password;
      };
    };
    guiAddress = "10.0.5.140:8384";
  };

  # Auto reset syncthing stuff
  systemd.services.syncthing-reset = {
    serviceConfig.Type = "oneshot";
    script = ''
      "${pkgs.curl}/bin/curl" -X POST -H "X-API-Key: garudalinux" http://10.0.5.140:8384/rest/db/override?folder=${garuda-lib.secrets.syncthing.folders.chaotic-aur}
    '';
  };
  systemd.timers.syncthing-reset = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = [ "hourly" ];
  };

  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  # Nginx
  services.nginx = {
    enable = true;
    virtualHosts = {
      "builds.garudalinux.org" = {
        extraConfig = ''
          # Disable index.html
          index fully_disabled.html;
          # Our beautiful autoindex theme
          autoindex on;
          autoindex_exact_size off;
          autoindex_format xml;
          xslt_string_param path $uri;
          xslt_string_param hostname "Chaotic-AUR main node - Temeraire";

          # Security
          add_header X-XSS-Protection          "1; mode=block" always;
          add_header X-Content-Type-Options    "nosniff" always;
          add_header Referrer-Policy           "no-referrer-when-downgrade" always;
          add_header Content-Security-Policy   "default-src 'self' http: https: data: blob: 'unsafe-inline'; frame-ancestors 'self' https://aur.chaotic.cx;" always;
          add_header Permissions-Policy        "interest-cohort=()" always;

          # Locations
          location ~* ^.+\.log {
              default_type text/plain;
          }
          location ~* /repos/(chaotic-aur|garuda)/x86_64/(?!.*(chaotic-aur|garuda)\.(db|files)).+\.tar.* {
              return 301 https://cf-builds.garudalinux.org$request_uri;
              expires 2d;
          }
          location /api/ {
              proxy_pass http://127.0.0.1:8080/api/;
          }
          location /backend/ {
              proxy_pass http://10.0.5.30:3000/;
          }
          location /logs/ {
              proxy_pass http://127.0.0.1:8080/;
              proxy_buffering off;
              proxy_read_timeout 330s;
          }
          location / {
              xslt_string_param path $uri;
              xslt_string_param hostname "Chaotic-AUR main node - Temeraire 🐉";
              xslt_stylesheet "${garuda-lib.xslt_style}";
              location /iso {
                  expires 2d;
                  return 301 https://iso.builds.garudalinux.org$request_uri;
              }
          }
        '';
        http3 = true;
        root = "/srv/http/";
      };
      "cf-builds.garudalinux.org" = {
        extraConfig = ''
          location ~* /repos/(chaotic-aur|garuda)/x86_64/(?!.*(chaotic-aur|garuda)\.(db|files)).+\.tar.* {
              add_header Cache-Control "max-age=150, stale-while-revalidate=150, stale-if-error=86400";
          }
          location ~* /repos/(chaotic-aur|garuda)/x86_64/(chaotic-aur|garuda)\.db.* {
              add_header Cache-Control 'no-cache';
          }
          location /repos/chaotic-aur {
              expires 5m;
              error_page 403 =301 https://builds.garudalinux.org$request_uri;
              error_page 404 =301 https://builds.garudalinux.org$request_uri;
          }
          location /repos/garuda {
              expires 5m;
              error_page 403 =301 https://builds.garudalinux.org$request_uri;
              error_page 404 =301 https://builds.garudalinux.org$request_uri;
          }
          location / {
              expires 2d;
              return 301 https://builds.garudalinux.org$request_uri;
          }
        '';
        http3 = true;
        root = "/srv/http/";
      };
      "iso.builds.garudalinux.org" = {
        extraConfig = ''
          autoindex on;
          autoindex_format xml;
          xslt_string_param path $uri;
          xslt_string_param hostname "Garuda Linux ISO Builds";
        '';
        locations."/".return = "307 https://builds.garudalinux.org";
        locations."/iso" = {
          root = "/srv/http/";
          extraConfig = ''
            xslt_stylesheet "${garuda-lib.xslt_style}";
            if ($symlink_target_rel != "") {
              rewrite ^ https://$server_name/iso/$symlink_target_rel redirect;
            }
            if ($arg_sourceforge) {
              rewrite ^/iso/(.*)$ https://sourceforge.net/projects/garuda-linux/files/$1? permanent;
            }
            if ($arg_r2) {
              set $args "";
              rewrite ^/iso/(.*)$ https://r2.garudalinux.org/iso/$1?r2request permanent;
            }
            break;
          '';
        };
      };
    };
  };

  # Rsyncd
  services.rsyncd = {
    enable = true;
    settings = {
      chaotic = {
        "read only" = "yes";
        comment = "Chaotic-AUR repository";
        exclude = "/chaotic-aur/archive/*** /garuda/archive/***";
        path = "/srv/http/repos/";
      };
      chaotic-minimal = {
        "read only" = "yes";
        comment = "Chaotic-AUR repository minus largest packages";
        exclude = "/chaotic-aur/archive/*** /garuda/archive/*** /chaotic-aur/x86_64/quartus* /chaotic-aur/x86_64/unrealtournament4* /chaotic-aur/x86_64/urbanterror*";
        path = "/srv/http/repos/";
      };
      iso = {
        path = "/srv/http/iso/";
        comment = "ISO downloads";
        "read only" = "yes";
      };
      global = {
        "max connections" = 80;
        "max verbosity" = 3;
        "transfer logging" = true;
        "use chroot" = false;
        gid = "nobody";
        uid = "nobody";
      };
    };
  };

  # Push chaotic to r2 hourly automatically
  services.garuda-rclone.chaotic = {
    src = "/srv/http/repos/";
    dest = "r2:/mirror/repos";
    config = garuda-lib.secrets.cloudflare.r2.rclone;
    args = "--s3-upload-cutoff 5G --s3-chunk-size 4G --fast-list --s3-no-head --s3-no-check-bucket --ignore-checksum --s3-disable-checksum -u --use-server-modtime --delete-during --delete-excluded --include /*/x86_64/*.pkg.tar.zst --include /*/lastupdate --order-by modtime,ascending --stats-log-level NOTICE";
    startAt = "hourly";
  };
  systemd.services.chaotic-rclone-inotify = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # Get all file changes, upload pkg.tar.zst. Not more than 5 per 5 seconds queued and only one uploaded at the same time. Queue dropped if uploading takes longer than 15 seconds.
    # This prevents the queue from getting overloaded with nonsense requests if that ever were to happen. The hourly sync should take care of this.
    script = ''
      upload() {
        operation="''${1%%|*}"
        path="''${1#*|}"
        relative="$(realpath --relative-to="." "$path")"
        relative="''${relative#./}"
        destpath="r2:/mirror/$relative"
        if [ "$operation" != "MOVED_FROM" ]; then
        ${pkgs.flock}/bin/flock -w 30 /tmp/chaotic-rclone-inotify.lock \
          ${pkgs.rclone}/bin/rclone copyto "$path" "$destpath" --s3-upload-cutoff 5G --s3-chunk-size 4G --s3-no-head --no-check-dest --s3-no-check-bucket --ignore-checksum --s3-disable-checksum --config "${garuda-lib.secrets.cloudflare.r2.rclone}" --stats-one-line -v
        else
          ${pkgs.flock}/bin/flock -w 30 /tmp/chaotic-rclone-inotify.lock ${pkgs.rclone}/bin/rclone deletefile "$destpath" --s3-no-head --no-check-dest --s3-no-check-bucket --config "${garuda-lib.secrets.cloudflare.r2.rclone}" --stats-one-line -v
          (
            ${pkgs.flock}/bin/flock -w 200 -s 200
            ${pkgs.curl}/bin/curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_GARUDALINUX_ORG/purge_cache" -H "Authorization: Bearer $CF_CACHE_API_TOKEN" -H "Content-Type:application/json" --data "{\"files\":[\"https://r2.garudalinux.org/''${relative}\"]}"
            sleep 0.5
          ) 200>/tmp/chaotic-rclone-inotify-invalidate.lock
        fi
      }
      export -f upload
      ${pkgs.inotify-tools}/bin/inotifywait -m ./repos/*/x86_64 -e CLOSE_WRITE,MOVED_TO,MOVED_FROM --format "%e|%w%f" | \
        ${pkgs.gawk}/bin/awk '/\.pkg\.tar\.zst$/ { print $0; fflush(); }' | \
        xargs -rP 0 -I % ${pkgs.bash}/bin/bash -c 'upload "%"'
    '';
    serviceConfig = {
      EnvironmentFile = garuda-lib.secrets.cloudflare.apikeys;
      Restart = "always";
      WorkingDirectory = "/srv/http";
    };
  };

  system.stateVersion = "23.05";
}
