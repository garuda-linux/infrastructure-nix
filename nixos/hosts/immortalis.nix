{ garuda-lib
, pkgs
, ...
}: {
  imports = [
    ../modules
    ./immortalis/containers.nix
    ./immortalis/hardware-configuration.nix
  ];

  # Increase /tmp & /run size to make better use of RAM
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    runSize = "50%";
    tmp = {
      tmpfsSize = "95%";
      useTmpfs = true;
    };
  };

  # Network configuration with a bridge interface
  networking = {
    defaultGateway = "116.202.208.65";
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    hostName = "immortalis";
    interfaces = {
      "eth0" = {
        ipv4.addresses = [
          {
            address = "116.202.208.112";
            prefixLength = 26;
          }
        ];
        ipv6.addresses = [
          # Random outgoing
          {
            address = "2a01:4f8:2200:30ac:deb5:0bf0:a197:9dda";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:0860:e20f:d76a:e86d";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:eed4:e800:82af:23ee";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:6784:0b97:6e5c:58c0";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:a9dc:093d:0c36:e397";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:769c:f08f:8bc5:37ae";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:70ae:06d0:5428:6c6e";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:14dd:95dc:bac2:f7a2";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:6500:13c1:ea05:4c0b";
            prefixLength = 64;
          }
          {
            address = "2a01:4f8:2200:30ac:2576:3beb:1d96:50e9";
            prefixLength = 64;
          }
        ];
      };
    };
    # Specify these here to allow containers to access
    # our services from the internal network via NAT reflection
    nat.forwardPorts = [
      {
        destination = "10.0.5.10:80";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 80;
      }
      {
        destination = "10.0.5.10:443";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 443;
      }
      {
        destination = "10.0.5.10:443";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "udp";
        sourcePort = 443;
      }
      {
        destination = "10.0.5.10:8448";
        loopbackIPs = [ "116.202.208.112" ];
        proto = "tcp";
        sourcePort = 8448;
      }
    ];
    firewall.trustedInterfaces = [ "br0" ];
  };

  # OpenSSH on another port to keep Chaotic's main node working
  services.openssh.ports = [ 666 ];

  # Make use of all threads!
  security.allowSimultaneousMultithreading = true;

  # Raise limits to support many containers
  # (from LXC's recommendedSysctlSettings)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 1048576;
    "fs.inotify.max_user_watches" = 1048576;
    "kernel.dmesg_restrict" = 1;
    "kernel.keys.maxkeys" = 2000;
    "kernel.pid_max" = 4194303;
    "net.ipv4.neigh.default.gc_thresh3" = 8192;
    "net.ipv6.neigh.default.gc_thresh3" = 8192;
  };

  # Improve nspawn container performance since we grant all capabilities anyway
  # https://github.com/systemd/systemd/issues/18370#issuecomment-768645418
  environment.variables.SYSTEMD_SECCOMP = "0";

  # Custom tailscale configuration to advertise our bridge's subnet route
  systemd.services.tailscale-autoconnect.script = with pkgs; ''
    sleep 2
    status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
    if [ $status = "Running" ]; then
      exit 0
    fi
    ${tailscale}/bin/tailscale up --authkey ${garuda-lib.secrets.tailscale.authkey} \
      --advertise-routes=10.0.5.0/24
  '';

  # We want to have same UID's in all containers to allow sharing home directories
  garuda-lib.unifiedUID = true;

  # Monitor a few services of the containers
  services = {
    netdata.configDir = {
      "go.d/postgres.conf" = pkgs.writeText "postgres.conf" ''
        jobs:
          - name: postgres
            dsn: 'postgres://netdata:netdata@10.0.5.50:5432/'
      '';
      "go.d/squidlog.conf" = pkgs.writeText "squidlog.conf" ''
        jobs:
          - name: squid
            path: /var/log/squid/access.log
            log_type: csv
            csv_config:
              format: '- resp_time client_address result_code resp_size req_method - - hierarchy mime_type'
      '';
      "go.d/web_log.conf" = pkgs.writeText "web_log.conf" ''
        jobs:
          - name: nginx
            path: /var/log/nginx/access.log
      '';
    };
    smartd = {
      enable = true;
      extraOptions = [ "-A /var/log/smartd/" "--interval=600" ];
    };
  };

  # Fix permissions of nginx log files to allow Netdata to read it (gets reset frequently)
  system.activationScripts.netdata = ''chown 60:netdata -R /var/log/nginx'';

  # Backup configurations to Hetzner storage box
  programs.ssh.macs = [ "hmac-sha2-512" ];
  services.borgbackup.jobs = {
    backupToHetzner = {
      compression = "auto,zstd";
      doInit = true;
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /var/garuda/secrets/backup/repo_key";
      };
      environment = {
        BORG_RSH = "ssh -i /var/garuda/secrets/backup/ssh_immortalis -p 23";
      };
      exclude = [ "/data_1/dockercache" "/data_1/dockerdata" ];
      paths = [ "/data_1" ];
      prune.keep = {
        within = "1d";
        daily = 3;
        weekly = 2;
        monthly = 2;
      };
      repo = "u342919@u342919.your-storagebox.de:./immortalis";
      startAt = "daily";
    };
  };

  # A proxy server making use of our IPv6 IP addresses
  # traffic sent through the proxy is only allowing IPv6 connections
  services.squid = {
    enable = true;
    extraConfig = ''
      forwarded_for delete
      dns_nameservers 2606:4700:4700::1111

      acl tenth random 1/10
      acl ninth random 1/9
      acl eighth random 1/8
      acl seventh random 1/7
      acl sixth random 1/6
      acl fifth random 1/5
      acl fourth random 1/4
      acl third random 1/3
      acl half random 1/2

      # Invalid IP
      tcp_outgoing_address 10.254.254.254
      tcp_outgoing_address 2a01:4f8:2200:30ac:0860:e20f:d76a:e86d tenth
      tcp_outgoing_address 2a01:4f8:2200:30ac:eed4:e800:82af:23ee ninth
      tcp_outgoing_address 2a01:4f8:2200:30ac:6784:0b97:6e5c:58c0 eighth
      tcp_outgoing_address 2a01:4f8:2200:30ac:a9dc:093d:0c36:e397 seventh
      tcp_outgoing_address 2a01:4f8:2200:30ac:769c:f08f:8bc5:37ae sixth
      tcp_outgoing_address 2a01:4f8:2200:30ac:70ae:06d0:5428:6c6e fifth
      tcp_outgoing_address 2a01:4f8:2200:30ac:14dd:95dc:bac2:f7a2 fourth
      tcp_outgoing_address 2a01:4f8:2200:30ac:6500:13c1:ea05:4c0b third
      tcp_outgoing_address 2a01:4f8:2200:30ac:2576:3beb:1d96:50e9 half
      tcp_outgoing_address 2a01:4f8:2200:30ac:deb5:0bf0:a197:9dda

      # Invalid IP
      udp_outgoing_address 10.254.254.254
      udp_outgoing_address 2a01:4f8:2200:30ac:0860:e20f:d76a:e86d tenth
      udp_outgoing_address 2a01:4f8:2200:30ac:eed4:e800:82af:23ee ninth
      udp_outgoing_address 2a01:4f8:2200:30ac:6784:0b97:6e5c:58c0 eighth
      udp_outgoing_address 2a01:4f8:2200:30ac:a9dc:093d:0c36:e397 seventh
      udp_outgoing_address 2a01:4f8:2200:30ac:769c:f08f:8bc5:37ae sixth
      udp_outgoing_address 2a01:4f8:2200:30ac:70ae:06d0:5428:6c6e fifth
      udp_outgoing_address 2a01:4f8:2200:30ac:14dd:95dc:bac2:f7a2 fourth
      udp_outgoing_address 2a01:4f8:2200:30ac:6500:13c1:ea05:4c0b third
      udp_outgoing_address 2a01:4f8:2200:30ac:2576:3beb:1d96:50e9 half
      udp_outgoing_address 2a01:4f8:2200:30ac:deb5:0bf0:a197:9dda
    '';
    proxyAddress = "10.0.5.1";
  };
  # Shut off all logging but level 1 errors as we get spamming a lot due to
  # not being able to use our invalid address 10.254.254.254
  systemd.services.squid.serviceConfig.LogLevelMax = 1;

  # Can't really instantly remove this, need to find an alternative first
  nixpkgs.config.permittedInsecurePackages = [ "squid-5.9" ];

  # Adapt Nix to our core-count
  nix.settings.max-jobs = 8;

  system.stateVersion = "23.05";
}
