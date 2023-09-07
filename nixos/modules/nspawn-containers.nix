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
                hostPath = "/etc/ssh/";
                isReadOnly = true;
                mountPoint = "/etc/ssh.host/";
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

    environment.etc = lib.mapAttrs'
      (name: value: lib.nameValuePair "systemd/nspawn/${name}.nspawn" {
        text = ''
          [Exec]
          SystemCallFilter=add_key keyctl bpf
        '';
      })
      (lib.filterAttrs (name: value: value.needsDocker) cfg.containers);

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
        enableIPv6 = false;
        externalInterface = cfg.hostInterface;
        internalInterfaces = [ cfg.bridgeInterface ];
      };
    };
  };
}
