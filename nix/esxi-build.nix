{
  config,
  garuda-lib,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-build";
  networking.interfaces.ens33.ipv4.addresses = [
    {
      address = "192.168.1.60";
      prefixLength = 24;
    }
  ];
  networking.defaultGateway = "192.168.1.1";

  # Lets build Garuda isos here
  services.garuda-iso.enable = true;
  # This disables HTTPS certificates and forced redirects
  garuda-lib.behind_proxy = true;

  # Openssh HPN for the performance gains
  programs.ssh.package = pkgs.openssh_hpn;

  # Enable Chaotic-AUR building
  services.chaotic.enable = true;
  services.chaotic.cluster-name = "garuda-cluster";
  # Let nginx set itself up for this local domain
  services.chaotic.host = "local.chaotic.invalid";
  services.chaotic.extraConfig = ''
    export CAUR_SIGN_KEY=BF773B6877808D28
    export CAUR_SIGN_USER=root
    export CAUR_TYPE=primary
    export CAUR_PACKAGER="Nico Jensch <dr460nf1r3@chaotic.cx>"
    export CAUR_URL=https://builds.garudalinux.org/repos/chaotic-aur/x86_64
    export CAUR_DEPLOY_LABEL="Temeraire 🐉"
    export CAUR_TELEGRAM_TAG="@dr460nf1r3"
    export REPOCTL_CONFIG=/usr/local/etc/chaotic-repoctl.toml
  '';
  services.chaotic.db-name = "chaotic-aur";
  services.chaotic.routines = ["hourly.1" "hourly.2" "afternoon" "nightly" "morning"];

  # Special Syncthing configuration allowing to push to main node
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    configDir = config.services.syncthing.dataDir;
    cert = garuda-lib.secrets.syncthing.esxi-build.cert;
    key = garuda-lib.secrets.syncthing.esxi-build.key;
    overrideFolders = false;
    overrideDevices = false;
    user = "root";
    group = "chaotic_op";
    extraOptions = {
      gui = {
        apikey = "garudalinux";
        insecureSkipHostcheck = true;
      };
    };
  };

  # Cloudflared access to Syncthing webinterface
  services.garuda-cloudflared = {
    enable = true;
    ingress = {"syncthing-build.garudalinux.net" = "http://localhost:8384";};
    tunnel-id = garuda-lib.secrets.cloudflare.cloudflared.esxi-build.id;
    tunnel-credentials =
      garuda-lib.secrets.cloudflare.cloudflared.esxi-build.cred;
  };

  # Auto reset syncthing stuff
  systemd.services.syncthing-reset = {
    serviceConfig.Type = "oneshot";
    script = ''
      "${pkgs.curl}/bin/curl" -X POST -H "X-API-Key: garudalinux" http://localhost:8384/rest/db/override?folder=${garuda-lib.secrets.syncthing.folders.chaotic-aur}
    '';
  };
  systemd.timers.syncthing-reset = {
    wantedBy = ["timers.target"];
    timerConfig.OnCalendar = ["hourly"];
  };

  # Chaotic-AUR builders need to upload their packages
  users.users.ufscar_hpc = {
    extraGroups = ["chaotic_op"];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFslN7a613H3hztK/yzHE4ZBOJ4448+EN867Y/IDpAfc u726578@c6.cluster.infra.ufscar.br"
    ];
  };
  users.users.catbuilder = {
    extraGroups = ["chaotic_op"];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHELhrMFNvxgAYMdzwerszypuvQc3uCFjkR6xCbcQnrcCrueJqTQ4y8WzddwxhRzKbSTQVhPdB5l95IYk7eOtmBmaMp4LAV2osMWDI/x3NyoY5s7YgpW815qNX9Io7VnrFUr0LK7hJ+Uw87nyxGp3zGddPVMUK7PIdJf2GxTxKPryycdLa9QWijfm3YBdN10yBMp6KrfPEnhtmNPMrc3wuBG4+xBoJxNOy0DJdIf2PRwU2CddP0zdDWwlMbGeHGcaJmlAx0u9e1jL8KWB/oyGT1D9q4l+fU8E9nZG+kAFMO1yG25je9bJnYNPMV1gdRT47G3J/B982XYO4G4AiOER0v0M0MN0qWTvIVBG6Vnly81ME91Qao34Lw2QOhZMVFwWz01u8KLLQy/Z2rX7jKyqeUyGXgs5NPmkeJ1vzpSRLXY+5GX5yva8A041Nft7sfKYPFjMsDaxAKVPz7LkKX1dYdiC4c3a/RcCzLKY+Uabjr0QAK4MKwmMW+SNF0QHr9mk= root@Chaotic"
    ];
  };
  users.users.chaotic-dragon = {
    extraGroups = ["chaotic_op"];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0zLuPM4IE4xsxen2XBqWKSQz5CpHONgguOhVuR5rTxRqijiwGro0VR4gPhpmuZjLkms4CJ2YGyjTbjDkh48+wAoiPjdvVqF6kJ9TLkHZabMJfx5chKMCVFcHM+0/F768fF/nRsfusbRO7H2nLGMXJ1eObemiCGg0e8Ccs0XA4PF9bGaDm+4bblNasVyT6PsnaYziyBtwU3fzBVbdQmErw37sjXV9jNsEq3XF9wSaFf/Dfzh9xY1CR1KC7Af84lL1vOj7QL06tEmDO6W4JJCpRS4OonpuahwaaR4gn6wW09eDgrpXUI5DhxGizwGPLdwENRONpcXP0xnWetC9IaUADHb9yZwQKZhN9RCoO5ytqrt/NkGfn7Si+mWSfMQRGvfgJocC89peIhbchXalT+JS1XWD+Isvj2I+sqmAcoKgji09MTF0lMW+m83/+YA7Jdhn5CLVs9RxZ5cwz1TqveuUaq4i9P867iKCltrqZxxgXD4emZXhHGvGrw8cNQZOVAhc= root@chaotic-dragon"
    ];
  };
  users.users.dragons-ryzen = {
    extraGroups = ["chaotic_op"];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAd8nLLjysVefmk3I6BI/IkooUvnGSy7966T54gWNvgW nico@slim-lair"
    ];
  };

  # Our main webserver on this machine
  services.nginx = {
    enable = true;
    virtualHosts = {
      "builds.garudalinux.org" = {
        extraConfig = ''
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
          add_header Content-Security-Policy   "default-src 'self' http: https: data: blob: 'unsafe-inline'; frame-ancestors 'self';" always;
          add_header Permissions-Policy        "interest-cohort=()" always;

          # Locations
          location ~* ^.+\.log {
              default_type text/plain;
          }
          location ~* /repos/(chaotic-aur|garuda)/x86_64/(?!.*(chaotic-aur|garuda)\.(db|files)).+\.tar.* {
              return 301 https://cf-builds.garudalinux.org$request_uri;
              expires 2d;
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
    };
  };

  # Explicitly open our firewall ports - HTTPS & rsyncd
  networking.firewall.allowedTCPPorts = [config.services.rsyncd.port];

  # Our rsyncd server
  services.rsyncd = {
    enable = true;
    settings = {
      chaotic = {
        "read only" = "yes";
        comment = "Chaotic-AUR repository";
        exclude = "/chaotic-aur/archive/*** /chaotic-aur/logs/***";
        path = "/srv/http/repos/";
      };
      chaotic-minimal = {
        "read only" = "yes";
        comment = "Chaotic-AUR repository minus largest packages";
        exclude = "/chaotic-aur/archive/*** /chaotic-aur/logs/*** /chaotic-aur/x86_64/quartus* /chaotic-aur/x86_64/unrealtournament4* /chaotic-aur/x86_64/urbanterror*";
        path = "/srv/http/repos/";
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
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    # Get all file changes, upload pkg.tar.zst. Not more than 5 per 5 seconds queued and only one uploaded at the same time. Queue dropped if uploading takes longer than 15 seconds.
    # This prevents the queue from getting overloaded with nonsense requests if that ever were to happen. The hourly sync should take care of this.
    script = ''
      set -eo pipefail
      upload() {
        operation="''${1%%|*}"
        path="''${1#*|}"
        relative="$(realpath --relative-to="." "$path")"
        relative="''${relative#./}"
        destpath="r2:/mirror/$relative"
        if [ "$operation" != "MOVED_FROM" ]; then
        ${pkgs.flock}/bin/flock -w 15 /tmp/chaotic-rclone-inotify.lock && \
          ${pkgs.rclone}/bin/rclone copyto "$path" "$destpath" --s3-upload-cutoff 5G --s3-chunk-size 4G --s3-no-head --no-check-dest --s3-no-check-bucket --ignore-checksum --s3-disable-checksum --config "${garuda-lib.secrets.cloudflare.r2.rclone}" --stats-one-line -v
        else
          ${pkgs.rclone}/bin/rclone deletefile "$destpath" --s3-no-head --no-check-dest --s3-no-check-bucket --config "${garuda-lib.secrets.cloudflare.r2.rclone}" --stats-one-line -v
          ${pkgs.curl}/bin/curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_GARUDALINUX_ORG/purge_cache" -H "Authorization: Bearer $CF_CACHE_API_TOKEN" -H "Content-Type:application/json" --data "{\"files\":[\"https://r2.garudalinux.org/''${relative}\"]}"
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

  # This is a containerized version of our esxi-repo configuration
  systemd.nspawn.esxi-repo = {
    enable = true;
    execConfig = {
      Boot = "yes";
      ResolvConf = "off";
      PrivateUsers = 0;
      Capability = "all";
    };
    filesConfig = {
      Bind = [
        "/srv/http/repos/garuda:/srv/http/repos/garuda"
        "/var/cache/pacman/pkg:/var/cache/pacman/pkg"
        "/var/cache/chaotic/packages:/var/cache/chaotic/packages"
      ];
    };
    networkConfig = {Interface = "ens35";};
  };
  systemd.services."systemd-nspawn@esxi-repo" = {
    overrideStrategy = "asDropin";
    wantedBy = ["machines.target"];
    environment = {SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1";};
    enable = true;
  };

  system.stateVersion = "22.05";
}
