{ garuda-lib, ... }: {
  imports = [ ./hardware-configuration.nix ./garuda/garuda.nix ];

  # Oracle provides DHCP
  networking.useDHCP = false;
  networking.interfaces.enp0s3.useDHCP = true;
  networking.hostName = "oracle-dragon";

  # The docker-compose stack holding Whoogle & Searx
  services.docker-compose-runner.oracle-dragon = {
    source = ./docker-compose/oracle-dragon;
    envfile = garuda-lib.secrets.docker-compose.oracle-dragon;
  };

  # Reverse proxy for our docker-compose stack
  services.nginx = {
    enable = true;
    # upstreams.whoogle.extraConfig = ''
    #   ip_hash;
    #   server esxi-web.local:5000;
    #   server web-dragon.local:5000;
    # '';
    virtualHosts = {
    #   "search-balance.garudalinux.org" = {
    #     addSSL = true;
    #     extraConfig = ''
    #       access_log off;
    #       ${garuda-lib.setRealIpFromConfig}
    #       real_ip_header CF-Connecting-IP;
    #     '';
    #     locations = { "/" = { proxyPass = "http://whoogle"; }; };
    #     http3 = true;
    #     useACMEHost = "garudalinux.org";
    #   };
      "search-2.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = { "/" = { proxyPass = "http://127.0.0.1:5000"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
      "searx-2.garudalinux.org" = {
        addSSL = true;
        extraConfig = ''
          access_log off;
          ${garuda-lib.setRealIpFromConfig}
          real_ip_header CF-Connecting-IP;
        '';
        locations = { "/" = { proxyPass = "http://127.0.0.1:8080"; }; };
        http3 = true;
        useACMEHost = "garudalinux.org";
      };
    };
  };
  system.stateVersion = "22.11";
}
