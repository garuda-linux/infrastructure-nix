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
    buildsChaotic = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
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
            "chaotic-cache" = lib.mkIf cont.buildsChaotic {
              hostPath = "data_2/containers/${name}/cache";
              isReadOnly = false;
              mountPoint = "/var/cache/chaotic";
            };
            "chaotic-libe" = lib.mkIf cont.buildsChaotic {
              hostPath = "data_2/containers/${name}/lib";
              isReadOnly = false;
              mountPoint = "/var/lib/chaotic";
            };
            "dev-fuse" = lib.mkIf cont.needsDocker {
              hostPath = "/dev/fuse";
              mountPoint = "/dev/fuse";
            };
            "home-ansible" = {
              hostPath = "/home/ansible";
              isReadOnly = false;
              mountPoint = "/home/ansible";
            };
            "home-nico" = {
              hostPath = "/home/nico";
              isReadOnly = false;
              mountPoint = "/home/nico";
            };
            "home-sgs" = {
              hostPath = "/home/sgs";
              isReadOnly = false;
              mountPoint = "/home/sgs";
            };
            "home-tne" = {
              hostPath = "/home/tne";
              isReadOnly = false;
              mountPoint = "/home/tne";
            };
            "home-technetium" = lib.mkIf cont.buildsChaotic {
              hostPath = "/home/technetium";
              isReadOnly = false;
              mountPoint = "/home/technetium";
            };
            "home-alexjp" = lib.mkIf cont.buildsChaotic {
              hostPath = "/home/alexjp";
              isReadOnly = false;
              mountPoint = "/home/alexjp";
            };
            "home-xiota" = lib.mkIf cont.buildsChaotic {
                hostPath = "/home/xiota";
                isReadOnly = false;
                mountPoint = "/home/xiota";
              };
            "keyring" = lib.mkIf cont.buildsChaotic {
              hostPath = "/root/.gnupg";
              isReadOnly = false;
              mountPoint = "/root/.gnupg";
            };
            "secrets" = lib.mkDefault {
              hostPath = "/var/garuda/secrets";
              isReadOnly = true;
              mountPoint = "/var/garuda/secrets";
            };
            "pacman" = lib.mkIf cont.buildsChaotic {
              hostPath = "/var/cache/pacman/pkg";
              isReadOnly = false;
              mountPoint = "/var/cache/pacman/pkg";
            };
            "telegram-send-group" = lib.mkIf cont.buildsChaotic {
              hostPath = "/var/garuda/secrets/chaotic/telegram-send-group"; #
              isReadOnly = true;
              mountPoint = "/root/.config/telegram-send-group.conf";
            };
            "telegram-send-log" = lib.mkIf cont.buildsChaotic {
              hostPath = "/var/garuda/secrets/chaotic/telegram-send-log";
              isReadOnly = true;
              mountPoint = "/root/.config/telegram-send-log.conf";
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
          specialArgs = sources.specialArgs;
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
