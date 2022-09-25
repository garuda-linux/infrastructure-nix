{ pkgs, ... }: {
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
  services.nginx.package = pkgs.nginx.override ({ withPerl = true; });
}
