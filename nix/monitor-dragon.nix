{ pkgs, garuda-lib, lib, ... }: {
  imports = [ ./garuda/garuda.nix ./garuda/common/lxc.nix ];

  # Base configuration
  networking.hostName = "monitor-dragon";
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.1.80";
    prefixLength = 24;
  }];
  networking.defaultGateway = "192.168.1.1";

  # Need to turn regular monitoring off to avoid conflicts
  services.garuda-monitoring.enable = lib.mkForce false;

  # Enable our Netdata parent node with a 40GB database
  services.netdata.enable = true;
  services.netdata.config = {
    global = {
      "dbengine multihost disk space" = "40960";
      "page cache size" = "3072";
      "update every" = "2";
    };
    web = { "bind to" = "127.0.0.1 10.241.0.10"; };
  };
  services.netdata.configDir = {
    "stream.conf" = pkgs.writeText "stream.conf" ''
      [${garuda-lib.secrets.netdata.stream_token}]
          allow from = 10.*
          default memory node = dbengine
          enable compression = yes
          enabled = yes
          health enabled by default = auto

      [logs]
          debug log = none
          error log = none
          access log = none
    '';
    "health_alarm_notify.conf" = pkgs.writeText "health_alarm_notify.conf" ''
      DEFAULT_RECIPIENT_TELEGRAM=${garuda-lib.secrets.telegram.monitoring_channel}
      SEND_TELEGRAM="YES"
      TELEGRAM_BOT_TOKEN=${garuda-lib.secrets.telegram.token}
    '';
  };

  # Required in order to let streaming connect to the parent
  networking.firewall.interfaces."ztnfabfexz" = {
    allowedTCPPorts = [ 19999 ];
    allowedUDPPorts = [ 19999 ];
  };

  # Make the Netdata parent node available via Cloudflared
  services.cloudflared = {
    enable = true;
    ingress = { "netdata.garudalinux.net" = "http://localhost:19999"; };
    tunnel-id = garuda-lib.secrets.cloudflared.monitor-dragon.id;
    tunnel-credentials = garuda-lib.secrets.cloudflared.monitor-dragon.cred;
  };

  system.stateVersion = "22.05";
}
