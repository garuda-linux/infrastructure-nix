{ garuda-lib
, ...
}: {
  imports = [
    ./garuda/common/lxc.nix
    ./garuda/garuda.nix
  ];

  # Base configuration
  networking.defaultGateway = "192.168.1.1";
  networking.hostName = "web-dragon";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "192.168.1.60";
      prefixLength = 24;
    }
  ];

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
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_web-dragon";
      };
      paths = [ "/var/garuda/docker-compose-runner/web-dragon" ];
      prune.keep = {
        daily = 3;
        monthly = 1;
        weekly = 2;
        within = "1d";
      };
      repo = "borg@192.168.1.70:.";
      startAt = "daily";
    };
  };

  # Enable our docker-compose stack
  services.docker-compose-runner.web-dragon = {
    envfile = garuda-lib.secrets.docker-compose.web-dragon;
    source = ./docker-compose/web-dragon;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "piped.garudalinux.org" = {
        addSSL = true;
        # extraConfig = ''
        #   location / {
        #     access_log off;
        #     ${garuda-lib.setRealIpFromConfig}
        #     real_ip_header CF-Connecting-IP;
        #     proxy_buffering off;
        #     proxy_pass http://127.0.0.1:8082;
        #     proxy_set_header Host $host;
        #   }
        # '';
        http3 = true;
        globalRedirect = "piped.video";
        serverAliases = [ "piped-api.garudalinux.org" "piped-proxy.garudalinux.org" ];
        useACMEHost = "garudalinux.org";
      };
      "invidious.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        # locations = {
        #   "/" = {
        #     extraConfig = ''
        #       access_log off;
        #       proxy_buffering off;
        #       proxy_set_header Connection "";
        #       proxy_http_version 1.1;
        #     '';
        #     proxyPass = "http://127.0.0.1:3001";
        #   };
        # };
        globalRedirect = "invidious.snopyta.org";
        useACMEHost = "garudalinux.org";
      };
      "teddit.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:8081";
          };
        };
        useACMEHost = "garudalinux.org";
      };
      "lingva.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:3000";
          };
        };
        useACMEHost = "garudalinux.org";
      };
      "nitter.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:8888";
          };
        };
        useACMEHost = "garudalinux.org";
      };
      "libreddit.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:8083";
          };
        };
        useACMEHost = "garudalinux.org";
      };
      "chaotic.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "proxy_max_temp_file_size 0;";
            proxyPass = "http://192.168.1.50:80";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
      "search.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:5000";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
      "searx.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        globalRedirect = "searx.garudalinux.org";
        http3 = true;
        useACMEHost = "dr460nf1r3.org";
      };
      "translate.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:3000";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
      "twitter.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:8888";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
      "reddit.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:8083";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
      "insta.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        http3 = true;
        locations = {
          "/" = {
            extraConfig = "access_log off;";
            proxyPass = "http://127.0.0.1:10407";
          };
        };
        useACMEHost = "dr460nf1r3.org";
      };
    };
  };
  system.stateVersion = "22.05";
}
