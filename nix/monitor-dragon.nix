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
    web = { "bind to" = "localhost monitor-dragon.local 192.168.1.80"; };
  };
  services.netdata.configDir = {
    "stream.conf" = pkgs.writeText "stream.conf" ''
      [${garuda-lib.secrets.netdata.stream_token}]
          allow from = *
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
    # Silence annoying Netdata warnings which are expected due to this being a builder
    "health.d/cpu.conf" = pkgs.writeText "cpu.conf" ''
      template: 10min_cpu_usage
      on: system.cpu
      class: Utilization
      type: System
      component: CPU
      os: linux
      hosts: *
      lookup: average -10m unaligned of user,system,softirq,irq,guest
      units: %
      every: 1m
      warn: $this > (($status >= $WARNING)  ? (75) : (85))
      crit: $this > (($status == $CRITICAL) ? (85) : (95))
      delay: down 15m multiplier 1.5 max 1h
      info: average CPU utilization over the last 10 minutes (excluding iowait, nice and steal)
      to: silent
    '';
    "health.d/cgroups.conf" = pkgs.writeText "cgroups.conf" ''
      template: cgroup_10min_cpu_usage
      on: cgroup.cpu_limit
      class: Utilization
      type: Cgroups
      component: CPU
      os: linux
      hosts: *
      lookup: average -10m unaligned
      units: %
      every: 1m
      warn: $this > (($status >= $WARNING)  ? (75) : (85))
      crit: $this > (($status == $CRITICAL) ? (85) : (95))
      delay: down 15m multiplier 1.5 max 1h
      info: average cgroup CPU utilization over the last 10 minutes
      to: silent
    '';
    "health.d/net.conf" = pkgs.writeText "net.conf" ''
      template: 1m_sent_traffic_overflow
      on: net.net
      class: Workload
      type: System
      component: Network
      os: linux
      hosts: *
      families: *
      lookup: average -1m unaligned absolute of sent
      calc: ($interface_speed > 0) ? ($this * 100 / ($interface_speed)) : ( nan )
      units: %
      every: 10s
      warn: $this > (($status >= $WARNING)  ? (85) : (90))
      delay: up 1m down 1m multiplier 1.5 max 1h
      info: average outbound utilization for the network interface $family over the last minute
      to: silent
    '';
    "health.d/load.conf" = pkgs.writeText "net.conf" ''
      alarm: load_average_15
      on: system.load
      class: Utilization
      type: System
      component: Load
      os: linux
      hosts: *
      lookup: max -1m unaligned of load15
      calc: ($load_cpu_number == nan) ? (nan) : ($this)
      units: load
      every: 1m
      warn: ($this * 100 / $load_cpu_number) > (($status >= $WARNING) ? 175 : 200)
      delay: down 15m multiplier 1.5 max 1h
      info: system fifteen-minute load average
      to: silent
    '';
  };

  # Allow web-dragon to send data
  networking.firewall = {
    allowedTCPPorts = [ 19999 ];
    allowedUDPPorts = [ 19999 ];
  };

  # Make the Netdata parent node available via Cloudflared
  services.garuda-cloudflared = {
    enable = true;
    ingress = { "netdata.garudalinux.net" = "http://localhost:19999"; };
    tunnel-id = garuda-lib.secrets.cloudflare.cloudflared.monitor-dragon.id;
    tunnel-credentials = garuda-lib.secrets.cloudflare.cloudflared.monitor-dragon.cred;
  };

  system.stateVersion = "22.05";
}
