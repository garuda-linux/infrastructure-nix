{ garuda-lib
, sources
, ...
}: {
  imports = sources.defaultModules ++ [
    ../garuda/garuda.nix
  ];

  # Our Lemmy instance
  services.lemmy = {
    database.uri = "postgresql://lemmy:${garuda-lib.secrets.lemmy.database}@10.0.5.50/lemmy";
    enable = true;
    settings = {
      hostname = "lemmy.garudalinux.org";
      email = {
        smtp_server = "mail.garudalinux.net:587";
        smtp_login = "noreply@garudalinux.org";
        inherit (garuda-lib.secrets.lemmy) smtp_password;
        smtp_from_address = "noreply@garudalinux.org";
        tls_type = "starttls";
      };
    };
  };

  services.nginx = {
    enable = true;
    httpConfig = ''
      map "$request_method:$http_accept" $proxpass {
          # If no explicit matches exists below, send traffic to lemmy-ui
          default "http://lemmy-ui";

          # GET/HEAD requests that accepts ActivityPub or Linked Data JSON should go to lemmy
          # "~^(?:GET|HEAD):.*?application\/(?:activity|ld)\+json" "http://lemmy";

          # All non-GET/HEAD requests should go to lemmy
          "~^(?!(GET|HEAD)).*:" "http://lemmy";
      }

      upstream lemmy {
        server "127.0.0.1:8536";
      }
      upstream lemmy-ui {
        server "127.0.0.1:1234";
      }
      
      server {
          listen 80;
          
          server_name lemmy.garudalinux.org;
          server_tokens off;

          gzip on;
          gzip_types text/css application/javascript image/svg+xml;
          gzip_vary on;

          client_max_body_size 25M;

          add_header X-Frame-Options SAMEORIGIN;
          add_header X-Content-Type-Options nosniff;
          add_header X-XSS-Protection "1; mode=block";

          # frontend general requests
          location / {
              proxy_pass $proxpass;
              rewrite ^(.+)/+$ $1 permanent;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header Host $host;
          }

          # backend
          location ~ ^/(api|pictrs|feeds|nodeinfo|.well-known) {
              proxy_pass "http://lemmy";
              proxy_http_version 1.1;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "upgrade";
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header Host $host;
          }
      }
    '';
  };

  system.stateVersion = "23.05";
}

