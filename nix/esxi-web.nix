{ garuda-lib, ... }: {
  imports = [ ./garuda/garuda.nix ./hardware-configuration.nix ];

  # Base configuration
  networking.hostName = "esxi-web";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.50";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Configure backups to backup-dragon
  services.borgbackup.jobs = {
    backupToBackupDragon = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-web -p 666";
      };
      paths = [ "/var/garuda/docker-compose-runner/esxi-web" ];
      prune.keep = {
        within = "1d";
        daily = 7;
        weekly = 2;
        monthly = 1;
      };
      repo = "borg@89.58.13.188:.";
      startAt = "daily";
    };
  };

  # Enable our docker-compose stack
  services.docker-compose-runner.esxi-web = {
    source = ./docker-compose/esxi-web;
    envfile = garuda-lib.secrets.docker-compose.esxi-web;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            index = "index.html";
            root = "/var/garuda/docker-compose-runner/esxi-web/website";
          };
          "/discord" = {
            extraConfig = "expires 12h;";
            return = "307 https://discord.gg/w5jbhq3juh";
          };
          "/telegram" = {
            extraConfig = "expires 12h;";
            return = "307 https://t.me/garudalinux";
          };
          "/os/garuda-update/backuprepo" = {
            extraConfig = ''
              rewrite ^/os/garuda-update/backuprepo/(.*)$ https://geo-mirror.chaotic.cx/chaotic-aur/$1 redirect;
            '';
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "cloud.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            extraConfig = ''
              # Increase our buffer size to allow bigger up- & downloads
              proxy_max_temp_file_size              2048M;
              proxy_request_buffering               off;

              # Needed to actually forward the real IPs 
              set_real_ip_from      172.0.0.0/16;
            '';
          };
          "/.well-known/carddav" = {
            extraConfig = "expires 12h;";
            return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/caldav" = {
            extraConfig = "expires 12h;";
            return = "301 $scheme://$host/remote.php/dav";
          };
          "/.well-known/webfinger" = {
            return = "301 $scheme://$host/index.php/.well-known/webfinger";
            extraConfig = ''
              access_log    off;
              log_not_found off;
            '';
          };
          "/.well-known/nodeinfo" = {
            extraConfig = ''
              access_log    off;
              log_not_found off;
            '';
            return = "301 $scheme://$host/index.php/.well-known/nodeinfo";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "search.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:5000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "searx.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:8080"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:5001"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "repo.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://192.168.1.30:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "start.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://127.0.0.1:8083"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "irc.garudalinux.org" = {
        addSSL = true;
        locations = { "/" = { proxyPass = "http://127.0.0.1:9000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bin.garudalinux.org" = {
        addSSL = true;
        extraConfig = "access_log off;";
        locations = { "/" = { proxyPass = "http://127.0.0.1:8083"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bitwarden.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8082";
            proxyWebsockets = true;
          };
        };
        http3 = true;
        serverAliases = [ "vault.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "status.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { tryFiles = "/status.html /status.html"; };
          "=/status.html" = {
            extraConfig = "expires 30d;";
            root = "/var/garuda/docker-compose-runner/esxi-web/website";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "stats.garudalinux.org" = {
        addSSL = true;
        locations = {
          "/" = { tryFiles = "/stats.html /stats.html"; };
          "=/stats.html" = {
            extraConfig = "expires 30d;";
            root = "/var/garuda/docker-compose-runner/esxi-web/website";
          };
        };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "forum.garudalinux.org" = {
        addSSL = true;
        extraConfig = "client_max_body_size  100M;";
        locations = { "/" = { proxyPass = "http://192.168.1.70:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "iso-builds.garudalinux.org" = {
        addSSL = true;
        extraConfig = "proxy_buffering off;";
        locations = { "/" = { proxyPass = "http://192.168.1.60:80"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };

  system.stateVersion = "22.05";
}
