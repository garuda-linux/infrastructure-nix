{ config
, lib
, pkgs
, ...
}: {
  # Recommended settings replacing custom configuration
  services.nginx = {
    additionalModules = with pkgs; [ nginxModules.brotli ];
    appendConfig = ''
      worker_processes auto;
    '';
    appendHttpConfig = ''
      map $uri $uri_dirname {
        ~^(?<capture>.*)/ $capture;
      }

      perl_set $symlink_target_rel '
        sub {
          my $r = shift;
          my $filename = $r->filename;
          return "" if ! -l $filename;
          my $target = readlink($filename);
          $target =~ s |.*/(.*/.*/.*/)|\1|s;
          return $target;
        }
      ';
    '';
    commonHttpConfig = ''
      # Recommended configuration
      ssl_ecdh_curve          X25519:secp521r1:secp384r1:prime256v1;
      resolver_timeout        2s;

      # Brotli compression
      brotli                  on;
      brotli_comp_level       6;
      brotli_static           on;
      brotli_types            application/atom+xml application/javascript application/json application/rss+xml
                              application/vnd.ms-fontobject application/x-font-opentype application/x-font-truetype
                              application/x-font-ttf application/x-javascript application/xhtml+xml application/xml
                              font/eot font/opentype font/otf font/truetype image/svg+xml image/vnd.microsoft.icon
                              image/x-icon image/x-win-bitmap text/css text/javascript text/plain text/xml;
    '';
    eventsConfig = ''
      worker_connections 1024;
    '';
    package = pkgs.nginx.override {
      withPerl = true;
      doCheck = false;
    };
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedZstdSettings = true;
    resolver = {
      addresses = [ "1.1.1.1" "1.0.0.1" "[2606:4700:4700::1111]" "[2606:4700:4700::1001]" ];
      valid = "60s";
    };
    statusPage = true;
  };

  # Diffie-Hellman parameter for DHE ciphersuites
  security.dhparams = lib.mkIf config.services.nginx.enable {
    enable = true;
    params.nginx = { };
  };
  services.nginx.sslDhparam = config.security.dhparams.params.nginx.path;

  # Need to explicitly open our web server ports
  networking.firewall = lib.mkIf config.services.nginx.enable {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };

  # Purge logfiles after 30 days
  services.logrotate.settings.nginx = {
    compress = true;
    delaycompress = true;
    files = "/var/log/nginx/*.log";
    frequency = "daily";
    rotate = 30;
  };
}
