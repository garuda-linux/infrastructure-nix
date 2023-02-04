{ config, garuda-lib, lib, pkgs, ... }: {
  imports = [
    ./garuda/common/esxi.nix
    ./garuda/garuda.nix
    ./hardware-configuration.nix
  ];

  # Base configuration
  networking.hostName = "esxi-build";
  networking.interfaces.ens33.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
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
  services.chaotic.routines =
    [ "hourly.1" "hourly.2" "afternoon" "nightly" "morning" ];

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
    ingress = { "syncthing-build.garudalinux.net" = "http://localhost:8384"; };
    tunnel-id = garuda-lib.secrets.cloudflared.esxi-build.id;
    tunnel-credentials = garuda-lib.secrets.cloudflared.esxi-build.cred;
  };

  # Auto reset syncthing stuff
  systemd.services.syncthing-reset = {
    serviceConfig.Type = "oneshot";
    script = ''
      "${pkgs.curl}/bin/curl" -X POST -H "X-API-Key: garudalinux" http://localhost:8384/rest/db/override?folder=${garuda-lib.secrets.syncthing.folders.garuda}
    '';
  };
  systemd.timers.syncthing-reset = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = [ "hourly" ];
  };

  # Chaotic-AUR builders need to upload their packages
  users.users.ufscar_hpc = {
    extraGroups = [ "chaotic_op" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFslN7a613H3hztK/yzHE4ZBOJ4448+EN867Y/IDpAfc u726578@c6.cluster.infra.ufscar.br"
    ];
  };
  users.users.catbuilder = {
    extraGroups = [ "chaotic_op" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYCCLcCdqM3mOde62AaiU6eoi4f1uqAuArjwLsUvqhdgvqn8CddQuYUIKsJJ4Mvl0MTSi2HwMZgBf/psWS+BrHVaOUZ2ymsvvdzenLvmjFSXmuB/LyI9+WElKwq1QMJ9b+uqdASEvdV6sGZovRpylxwaftzm/E/4DAyV3i8+1iKpcSJK1JZ2052gvuojhRTAuCbEAkL3eu8MRoVqzpWuHYe658P48WtDLp3rba2Y+EMtl5ZXcz3Qvrf9CIX+enXo2LD+xJd9BFrrJiAHrY436aBF+tCdLVUdO6YiwC8WatRTJDCXdjpW4vlUvQnBaA2bwUSahrG2Cn0Ro82GMowmlCu1KqL3hOCgYLGuOAIWuNAKPvPzWYhuISMh8y9W/boK7h16B0H3I2pj28fOiKbze5LgHe6g4UJ5Qqb5UuBmTY7eylAZKmj+OAB67Tmgc/dErw2AW0mbukFSUZmpsMyuTRCumALq7swSY6U06hRKVWHN6InXT0xbBguct2SpSnW0c= root@CatBuilder"
    ];
  };
  users.users.chaotic-dragon = {
    extraGroups = [ "chaotic_op" ];
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0zLuPM4IE4xsxen2XBqWKSQz5CpHONgguOhVuR5rTxRqijiwGro0VR4gPhpmuZjLkms4CJ2YGyjTbjDkh48+wAoiPjdvVqF6kJ9TLkHZabMJfx5chKMCVFcHM+0/F768fF/nRsfusbRO7H2nLGMXJ1eObemiCGg0e8Ccs0XA4PF9bGaDm+4bblNasVyT6PsnaYziyBtwU3fzBVbdQmErw37sjXV9jNsEq3XF9wSaFf/Dfzh9xY1CR1KC7Af84lL1vOj7QL06tEmDO6W4JJCpRS4OonpuahwaaR4gn6wW09eDgrpXUI5DhxGizwGPLdwENRONpcXP0xnWetC9IaUADHb9yZwQKZhN9RCoO5ytqrt/NkGfn7Si+mWSfMQRGvfgJocC89peIhbchXalT+JS1XWD+Isvj2I+sqmAcoKgji09MTF0lMW+m83/+YA7Jdhn5CLVs9RxZ5cwz1TqveuUaq4i9P867iKCltrqZxxgXD4emZXhHGvGrw8cNQZOVAhc= root@chaotic-dragon"
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
          
          # We had tons of HEAD request spams requesting the same file over and over again
          if ($request_method = HEAD) {
              return 444;
          }

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
          # We had tons of HEAD request spams requesting the same file over and over again
          if ($request_method = HEAD) {
              return 444;
          }

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
  networking.firewall.allowedTCPPorts = [ config.services.rsyncd.port ];

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
        exclude =
          "/chaotic-aur/archive/*** /chaotic-aur/logs/*** /chaotic-aur/x86_64/quartus* /chaotic-aur/x86_64/unrealtournament4* /chaotic-aur/x86_64/urbanterror*";
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

  systemd.tmpfiles.rules = [
    "d /srv/http/iso 1555 root root"
  ];

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
      Bind = [ "/srv/http/repos/garuda:/srv/http/repos/garuda" "/var/cache/pacman/pkg:/var/cache/pacman/pkg" "/var/cache/chaotic/packages:/var/cache/chaotic/packages" ];
    };
    networkConfig = {
      Interface = "ens35";
    };
  };
  systemd.services."systemd-nspawn@esxi-repo" = {
    overrideStrategy = "asDropin";
    wantedBy = [ "machines.target" ];
    environment = { SYSTEMD_NSPAWN_UNIFIED_HIERARCHY = "1"; };
    enable = true;
  };

  system.stateVersion = "22.05";
}
