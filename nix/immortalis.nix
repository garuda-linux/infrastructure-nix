{ config, lib, sources, ... }:
let
  mkContainer = name: extra:
    lib.mkMerge [{
      autoStart = true;
      config = import ./${name}.nix;
      specialArgs = sources.specialArgs;
      enableTun = true; # Tailscale
      ephemeral = false;
      privateNetwork = true;
      additionalCapabilities = [ "all" ];
      bindMounts = {
        "secrets" = lib.mkDefault {
          hostPath = "/var/garuda/secrets";
          mountPoint = "/var/garuda/secrets";
          isReadOnly = true;
        };
      };
    }
      extra];
in
{
  imports = [
    ./hardware-configuration.nix
    ./garuda/garuda.nix
  ];

  # Base network configuration
  networking.interfaces."eth0".ipv4.addresses = [{
    address = "116.202.208.112";
    prefixLength = 26;
  }];

  networking.hostName = "immortalis";
  networking.defaultGateway = "116.202.208.65";

  boot.loader.systemd-boot.enable = true;

  # Provide internet access to containers
  networking.nat = {
    enable = true;
    internalInterfaces = [ "ve-+" ];
    externalInterface = "eth0";
    enableIPv6 = true;
  };

  networking.interfaces."ve-repo".ipv4.addresses = [{
    address = "10.0.0.10";
    prefixLength = 8;
  }];

  containers = {
    "repo" = mkContainer "repo" {
      hostAddress = "10.0.0.10";
      localAddress = "10.0.0.11";
    };
  };

  system.stateVersion = "23.05";
}
