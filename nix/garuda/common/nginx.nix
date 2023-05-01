{ config
, lib
, pkgs
, ...
}: {
  # The Nginx QUIC package with Perl & Brotli modules
  services.nginx.package = pkgs.nginxQuic.override {
    withPerl = true;
    doCheck = false;
  };
  services.nginx.additionalModules = with pkgs; [ nginxModules.brotli ];

  # Recommended settings replacing custom configuration
  services.nginx.recommendedGzipSettings = true;
  services.nginx.recommendedOptimisation = true;
  services.nginx.recommendedTlsSettings = true;

  # Statuspage for Netdata to consume
  services.nginx.statusPage = true;

  # Upstream resolvers
  services.nginx.resolver = {
    addresses = [ "1.1.1.1" "1.0.0.1" "[2606:4700:4700::1111]" "[2606:4700:4700::1001]" ];
    valid = "60s";
  };

  # Global Nginx configuration
  services.nginx.appendConfig = ''
    worker_processes auto;
  '';

  # Adapt worker_connections to allow more concurrent connections
  services.nginx.eventsConfig = ''
    worker_connections 1024;
  '';

  # Correctly map symlinks
  services.nginx.appendHttpConfig = ''
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

  # Logformat to use for Netdata & extra config that doesn't exist as separate key in NixOS
  services.nginx.commonHttpConfig = ''
    # Recommended configuration
    ssl_ecdh_curve          X25519:secp521r1:secp384r1:prime256v1;
    resolver_timeout        2s;

    # Custom log format for Netdata to analyze
    log_format              custom '"$http_referer" "$http_user_agent" '
                            '$remote_addr - $remote_user [$time_local] '
                            '"$request" $status $body_bytes_sent';

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

  # Diffie-Hellman parameter for DHE ciphersuites
  security.dhparams = lib.mkIf config.services.nginx.enable {
    defaultBitSize = 3072;
    enable = true;
    params.nginx = { };
  };
  services.nginx.sslDhparam = config.security.dhparams.params.nginx.path;

  # Need to explicitly open our web server ports
  networking.firewall = lib.mkIf config.services.nginx.enable {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 443 ];
  };
}
