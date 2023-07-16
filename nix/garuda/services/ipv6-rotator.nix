{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.garuda-ipv6-rotator;

  ipv6-rotator = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ipv6-rotator";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "ycd";
      repo = "ipv6-rotator";
      rev = "d51f72b80381c7fa0903f5a238d1ac1454619a0e";
      hash = "sha256-A2yf+MHP+CTH36LLnmoSwMjPwKMi9HkAcgdyR9Jj4VU=";
    };
    cargoSha256 = "sha256-8WszhXoaqoox3M196rO47uZdG9CgGwaV1MwW+MVClBM=";
  };
in
{
  options.services.garuda-ipv6-rotator = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    network = mkOption {
      type = types.str;
      default = "null";
    };
    mask = mkOption {
      type = types.str;
      default = "64";
    };
    interface = mkOption {
      type = types.str;
      default = "null";
    };
    sleep = mkOption {
      type = types.str;
      default = "10";
    };
    count = mkOption {
      type = types.str;
      default = "5";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.ipv6-rotator = {
      wantedBy = [ "multi-user.target" ];
      description = "Rotate ipv6 addresses periodically";
      path = [ ipv6-rotator ];
      serviceConfig = {
        ExecStart = pkgs.writeShellScript "execstart" ''
          set -e
          ${ipv6-rotator}/bin/rotator \
            --network ${cfg.network} \
            --block ${cfg.mask} \
            --interface ${cfg.interface} \
            --sleep ${cfg.sleep} \
            --count ${cfg.count}
        '';
        Restart = "on-failure";
        RestartSec = "30";
      };
    };
    environment.systemPackages = [ ipv6-rotator ];
  };
}
