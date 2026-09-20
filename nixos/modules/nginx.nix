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

      # JSON access log for Loki with Cloudflare visitor-location headers
      log_format garuda_json escape=json
        '{"ts":"$time_iso8601","host":"$host","remote":"$remote_addr",'
        '"request":"$request","status":$status,"bytes":$bytes_sent,'
        '"req_time":$request_time,"upstream_time":"$upstream_response_time",'
        '"referer":"$http_referer","agent":"$http_user_agent",'
        '"cf_country":"$http_cf_ipcountry","cf_lat":"$http_cf_iplatitude",'
        '"cf_lon":"$http_cf_iplongitude","cf_ray":"$http_cf_ray",'
        '"tls":"$ssl_protocol"}';
      access_log /var/log/nginx/access.log garuda_json;

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
    package = pkgs.nginx.override {
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
