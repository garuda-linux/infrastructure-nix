{ garuda-lib, ... }: 
let
  piped = {
    addSSL = true;
    extraConfig = ''
      location / {
        proxy_buffering off;
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        access_log off;
        }
    '';
    http3 = true;
    useACMEHost = "garudalinux.org";
  };
in {
  imports = [ ./garuda/garuda.nix ];

  # Base configuration
  networking.hostName = "web-dragon";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.60";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # LXC support
  boot.loader.initScript.enable = true;
  boot.isContainer = true;
  systemd.enableUnifiedCgroupHierarchy = false;

  # Enable our docker-compose stack
  services.docker-compose-runner.web-dragon = {
    source = ./docker-compose/web-dragon;
    envfile = garuda-lib.secrets.docker-compose.web-dragon;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    virtualHosts = {
      "piped.garudalinux.org" = piped; 
      "piped-api.garudalinux.org" = piped;
      "piped-proxy.garudalinux.org" = piped;
      "invidious.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_buffering off;
            proxy_http_version 1.1;
            proxy_pass http://localhost:3001;
            proxy_set_header Connection "";
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $remote_addr;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "teddit.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:8081;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "lingva.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:3000;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "nitter.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:8888;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "libreddit.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:8083;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "bibliogram.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://localhost:10407;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Scheme $scheme;
            access_log off;
          }
        '';
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "chaotic.dr460nf1r3.org" = {
        addSSL = true;
        extraConfig = ''
          location / {
            proxy_pass http://192.168.1.50:80;
            proxy_max_temp_file_size 0;
            proxy_redirect off;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Host $server_name;
          }
        '';
        http3 = true;
        useACMEHost = "dr460nf1r3.org";
      };
    };
  };
  system.stateVersion = "22.05";
}
