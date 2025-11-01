{
  config,
  lib,
  pkgs,
  ...
}:
{
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
    eventsConfig = ''
      worker_connections 1024;
    '';
    package = pkgs.nginxQuic.override {
      withPerl = true;
      doCheck = false;
    };
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedBrotliSettings = true;
    resolver = {
      addresses = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      ipv6 = false;
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
    allowedTCPPorts = [
      80
      443
    ];
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
