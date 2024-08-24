{ config
, garuda-lib
, lib
, sources
, ...
}:
let
  cfg = config.services.garuda-nspawn;
  submoduleOptions.options = {
    config = lib.mkOption { };
    mountHome = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
    };
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
    restrictQuotas = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    defaults = lib.mkOption {
      type = lib.types.bool;
      default = true;
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
          additionalCapabilities = [ "all" ];
          allowedDevices = (lib.lists.optionals cont.needsDocker [
            { node = "/dev/fuse"; modifier = "rwm"; }
            { node = "/dev/mapper/control"; modifier = "rwm"; }
          ]) ++ (lib.lists.optionals cont.defaults [
            { node = "/dev/loop-control"; modifier = "rw"; }
            { node = "block-loop"; modifier = "rw"; }
          ]);
          autoStart = true;
          bindMounts = lib.mkMerge
            ((lib.lists.optional cont.defaults {
              "dev-loop0" = {
                hostPath = "/dev/loop0";
                mountPoint = "/dev/loop0";
              };
              "secrets" = {
                hostPath = "/var/garuda/secrets";
                isReadOnly = false;
                mountPoint = "/var/garuda/secrets";
              };
              "ssh_ed25519" = {
                hostPath = "/etc/ssh/";
                isReadOnly = true;
                mountPoint = "/etc/ssh.host/";
              };

            })
            ++ (lib.lists.optional (if builtins.isNull cont.mountHome then cont.defaults else cont.mountHome) {
              "home" = {
                hostPath = "/home";
                isReadOnly = false;
                mountPoint = "/home";
              };
            })
            ++ (lib.lists.optional cont.needsDocker {
              "dev-fuse" = {
                hostPath = "/dev/fuse";
                mountPoint = "/dev/fuse";
              };
              "dockercache" = {
                hostPath = "${cfg.dockerCache}/${name}";
                isReadOnly = false;
                mountPoint = "/var/lib/docker";
              };
            })
            );
          config = lib.mkMerge
            ([ cont.config ]
              ++ lib.lists.optional cont.defaults {
              config.garuda-lib.minimalContainer = true;
              config.services.openssh.hostKeys = [
                {
                  bits = 4096;
                  path = "/etc/ssh.host/ssh_host_rsa_key";
                  type = "rsa";
                }
                {
                  path = "/etc/ssh.host/ssh_host_ed25519_key";
                  type = "ed25519";
                }
              ];
            }
              ++ lib.lists.optional (garuda-lib.unifiedUID && cont.defaults) {
              config.garuda-lib.unifiedUID = true;
            });
          ephemeral = false;
          hostAddress = cfg.hostIp;
          hostBridge = cfg.bridgeInterface;
          localAddress = "${cont.ipAddress}/${builtins.toString cfg.networkPrefix}";
          privateNetwork = true;
          inherit (sources) specialArgs;
        }
          cont.extraOptions])
      cfg.containers;

    environment.etc = lib.mkMerge [
      (lib.mapAttrs'
        (name: _value: lib.nameValuePair "systemd/nspawn/${name}.nspawn" {
          text = ''
            [Exec]
            SystemCallFilter=add_key keyctl bpf
          '';
        })
        (lib.filterAttrs (_name: value: value.needsDocker) cfg.containers))
      (lib.mapAttrs'
        # This restricts container resources to 30 CPU cores and 90GB/100GB of memory.
        # Specifically, it should prevent one container to hog all resources.
        (name: _value: lib.nameValuePair "systemd/system.control/container@${name}.service.d/quotas.conf" {
          text = ''
            [Service]
            CPUAccounting=true
            CPUQuota=3000.00%
            MemoryAccounting=true
            MemoryHigh=96636764160
            MemoryMax=107374182400
          '';
        })
        (lib.filterAttrs (_name: value: value.restrictQuotas) cfg.containers))
    ];

    systemd.tmpfiles.rules = lib.mapAttrsToList (name: _value: "d ${cfg.dockerCache}/${name} 1555 root root") (lib.filterAttrs (_name: value: value.needsDocker) cfg.containers);

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
        enableIPv6 = false;
        externalInterface = cfg.hostInterface;
        internalInterfaces = [ cfg.bridgeInterface ];
      };
    };
  };
}
