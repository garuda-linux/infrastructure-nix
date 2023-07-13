{ config, lib, pkgs, sources, garuda-lib, ... }:
let
  cfg = config.services.garuda-nspawn;
  submoduleOptions.options = {
    config = lib.mkOption { };
    extraOptions = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
    ipAddress = lib.mkOption {
      type = lib.types.str;
    };
    needsDocker = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    needsNesting = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    cpuQuota = lib.mkOption {
      type = lib.types.ints.between 1 100;
      default = 80;
    };
    memoryHigh = lib.mkOption {
      type = lib.types.ints.positive;
      default = 60;
    };
    memoryMax = lib.mkOption {
      type = lib.types.ints.positive;
      default = 64;
    };
  };
in
{
  options.services.garuda-nspawn = {
    hostIp = lib.mkOption {
      type = lib.types.str;
    };
    hostInterface = lib.mkOption {
      type = lib.types.str;
    };
    bridgeInterface = lib.mkOption {
      type = lib.types.str;
    };
    networkPrefix = lib.mkOption {
      type = lib.types.ints.between 1 32;
      default = 24;
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule submoduleOptions);
      default = { };
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
            "secrets" = lib.mkDefault {
              hostPath = "/var/garuda/secrets";
              isReadOnly = true;
              mountPoint = "/var/garuda/secrets";
            };
            "dev-fuse" = lib.mkIf cont.needsDocker {
              hostPath = "/dev/fuse";
              mountPoint = "/dev/fuse";
            };
          };
          config = lib.mkMerge ([
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
      # network address translation from the internet to the bridge
      nat = {
        enable = true;
        internalInterfaces = [ cfg.bridgeInterface ];
        externalInterface = cfg.hostInterface;
        enableIPv6 = true;
      };
    };
  };
}
