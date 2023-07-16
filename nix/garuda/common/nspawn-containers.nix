{ config
, garuda-lib
, lib
, pkgs
, sources
, ...
}:
let
  cfg = config.services.garuda-nspawn;
  submoduleOptions.options = {
    config = lib.mkOption { };
    cpuQuota = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 80;
    };
    extraOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    ipAddress = lib.mkOption {
      type = lib.types.str;
    };
    memoryHigh = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
    };
    memoryMax = lib.mkOption {
      type = lib.types.ints.positive;
      default = 64;
    };
    needsDocker = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    needsNesting = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
in
{
  options.services.garuda-nspawn = {
    bridgeInterface = lib.mkOption {
      type = lib.types.str;
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule submoduleOptions);
      default = { };
    };
    hostInterface = lib.mkOption {
      type = lib.types.str;
    };
    hostIp = lib.mkOption {
      type = lib.types.str;
    };
    networkPrefix = lib.mkOption {
      type = lib.types.ints.between 1 32;
      default = 24;
    };
    dockerCache = lib.mkOption {
      type = lib.types.str;
    };
  };
  # lib.mkIf (cfg != { })
  config = {
    containers = lib.mapAttrs
      (name: value:
        let
          cont = value;
        in
        lib.mkMerge [{
          additionalCapabilities = lib.mkForce [ "all" ];
          allowedDevices = lib.lists.optionals cont.needsDocker [
            { node = "/dev/fuse"; modifier = "rwm"; }
            { node = "/dev/mapper/control"; modifier = "rwm"; }
          ];
          autoStart = true;
          bindMounts = {
            "dev-fuse" = lib.mkIf cont.needsDocker {
              hostPath = "/dev/fuse";
              mountPoint = "/dev/fuse";
            };
            "home" = {
              hostPath = "/home";
              isReadOnly = false;
              mountPoint = "/home";
            };
            "secrets" = {
              hostPath = "/var/garuda/secrets";
              isReadOnly = false;
              mountPoint = "/var/garuda/secrets";
            };
            "ssh_ed25519" = {
              hostPath = "/etc/ssh/ssh_host_ed25519_key";
              isReadOnly = true;
              mountPoint = "/etc/ssh/ssh_host_ed25519_key";
            };
            "ssh_ed25519_pub" = {
              hostPath = "/etc/ssh/ssh_host_ed25519_key.pub";
              isReadOnly = true;
              mountPoint = "/etc/ssh/ssh_host_ed25519_key.pub";
            };
            "ssh_rsa" = {
              hostPath = "/etc/ssh/ssh_host_rsa_key";
              isReadOnly = true;
              mountPoint = "/etc/ssh/ssh_host_rsa_key";
            };
            "ssh_rsa_pub" = {
              hostPath = "/etc/ssh/ssh_host_rsa_key.pub";
              isReadOnly = true;
              mountPoint = "/etc/ssh/ssh_host_rsa_key.pub";
            };
            "dockercache" = lib.mkIf cont.needsDocker {
              hostPath = "${cfg.dockerCache}/${name}";
              isReadOnly = false;
              mountPoint = "/var/lib/docker";
            };
          };
          config = lib.mkMerge
            ([
              cont.config
              {
                config.garuda-lib.minimalContainer = true;
              }
            ]
            ++ lib.lists.optional garuda-lib.unifiedUID {
              config.garuda-lib.unifiedUID = true;
            });
          ephemeral = true;
          extraFlags = [
            "--property=CPUQuota=${builtins.toString cont.cpuQuota}"
            "--property=MemoryHigh=${builtins.toString cont.memoryHigh}"
            "--property=MemoryMax=${builtins.toString cont.memoryMax}"
          ];
          hostAddress = cfg.hostIp;
          hostBridge = cfg.bridgeInterface;
          localAddress = "${cont.ipAddress}/${builtins.toString cfg.networkPrefix}";
          privateNetwork = true;
          inherit (sources) specialArgs;
        }
          cont.extraOptions])
      cfg.containers;

    environment.etc = lib.mapAttrs'
      (name: value: lib.nameValuePair "systemd/nspawn/${name}.nspawn" {
        text = ''
          [Exec]
          SystemCallFilter=add_key keyctl bpf
        '';
      })
      (lib.filterAttrs (name: value: value.needsDocker) cfg.containers);

    systemd.services = lib.mapAttrs'
      (name: value: lib.nameValuePair "container@${name}" {
        serviceConfig.ExecStartPost = [
          (pkgs.writeShellScript "container-${name}-post" ''
            "${pkgs.coreutils}/bin/echo" "mount -t cgroup2 -o rw,nosuid,nodev,noexec,relatime none /sys/fs/cgroup" | "${pkgs.nixos-container}/bin/nixos-container" root-login ${name}
          '')
        ];
      })
      (lib.filterAttrs (name: value: value.needsNesting) cfg.containers);

    systemd.tmpfiles.rules = lib.mapAttrsToList (name: value: "d ${cfg.dockerCache}/${name} 1555 root root") (lib.filterAttrs (name: value: value.needsDocker) cfg.containers);

    # Bridge setup
    networking = lib.mkIf (cfg.containers != { }) {
      bridges."${cfg.bridgeInterface}" = {
        interfaces = [ ];
      };
      interfaces."${cfg.bridgeInterface}".ipv4.addresses = [{
        address = cfg.hostIp;
        prefixLength = cfg.networkPrefix;
      }];
      # Network address translation from the internet to the bridge
      nat = {
        enable = true;
        enableIPv6 = true;
        externalInterface = cfg.hostInterface;
        internalInterfaces = [ cfg.bridgeInterface ];
      };
    };
  };
}
