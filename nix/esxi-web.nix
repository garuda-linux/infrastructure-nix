{ garuda-lib, ... }: {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "esxi-web";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.20";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Configure backups to backup-dragon
  services.borgbackup.jobs = {
    backupToBackupDragon = {
      paths = [ "/var/garuda/docker-compose-runner/esxi-web" ];
      doInit = true;
      repo = "borg@89.58.13.188:.";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_esxi-web -p 666";
      };
      compression = "auto,zstd";
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
      "cloud.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_max_temp_file_size              2048M;
            proxy_request_buffering               off;

            proxy_pass https://192.168.1.40:443;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Host $server_name;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Real-IP $remote_addr;
            
            # Needed to actually forward the real IPs 
            set_real_ip_from      172.0.0.0/16;
          }
          location /.well-known/carddav {
              return 301 $scheme://$host/remote.php/dav;
          }
          location /.well-known/caldav {
              return 301 $scheme://$host/remote.php/dav;
          }
          location /.well-known/webfinger {
              return 301 $scheme://$host/index.php/.well-known/webfinger;
              access_log    off;
              log_not_found off;
          }
          location /.well-known/nodeinfo {
              return 301 $scheme://$host/index.php/.well-known/nodeinfo;
              access_log    off;
              log_not_found off;
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "search.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            access_log off;
            proxy_buffering off;
            proxy_pass http://127.0.0.1:5000;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "searx.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            access_log off;
            proxy_buffering off;
            proxy_pass http://127.0.0.1:8080;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "ffsync.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_buffering off;
            proxy_pass http://127.0.0.1:5001;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "repo.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://192.168.1.30:80;
            proxy_buffering off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "start.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://127.0.0.1:8083;
            proxy_buffering off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "irc.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://127.0.0.1:9000;
            proxy_buffering off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bin.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_buffering off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            proxy_pass http://127.0.0.1:8083;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "status.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            try_files /status.html /status.html;
          }
          location =/status.html {
            expires 30d;
            root /usr/share/nginx/html/www;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "stats.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
           try_files /stats.html /stats.html;
          }
          location =/status.html {
            expires 30d;
            root /usr/share/nginx/html/www;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "forum.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            client_max_body_size  100M;
            proxy_pass http://192.168.1.70:80;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "iso-builds.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://192.168.1.60:80;
            proxy_buffering off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };

  system.stateVersion = "22.05";
}
