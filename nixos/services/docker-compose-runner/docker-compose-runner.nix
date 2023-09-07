{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.docker-compose-runner;
in
{
  options.services.docker-compose-runner = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        source = mkOption {
          type = types.path;
          description = "Folder containing a docker-compose file.";
        };
        envfile = mkOption {
          type = types.nullOr types.path;
          description = "Direct path to a valid .env file";
          default = null;
        };
        args = mkOption {
          type = types.str;
          description = "Additional arguments to pass to docker-compose up";
          default = "up";
        };
      };
    });
    default = { };
  };

  config = {
    systemd.services = mapAttrs'
      (name: value: nameValuePair ("docker-compose-runner-" + name) (
        let
          output = derivation {
            name = "docker-compose-runner-" + name;
            src = value.source;
            builder = pkgs.writeShellScript "build" ''
              PATH="${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin"
              set -e
              mkdir "$out"
              sed -r 's/(^\s+restart:\s*)(unless-stopped|always)(\s*($|#))/\1on-failure\3/g' "$src/docker-compose.yml" > "$out/docker-compose.yml"
              rsync -a "$src/" "$out"
            '';
            inherit (pkgs.hostPlatform) system;
          };
          statepath = "/var/garuda/docker-compose-runner/${name}";
        in
        {
          wantedBy = [ "multi-user.target" ];
          description = "docker-compose runner for ${name}";
          path = with pkgs; [ rsync docker-compose docker bash ];
          startLimitIntervalSec = 30;
          startLimitBurst = 3;
          serviceConfig = {
            ExecStart = pkgs.writeShellScript ("execstart-docker-compose-runner-" + name) ''
              set -e
              mkdir -p "${statepath}"
              rsync -a --no-owner --size-only "${output}/" "${statepath}"
              ${optionalString (value.envfile != null) ''
                  cp "${value.envfile}" "${statepath}/.env"
                  chmod 600 "${statepath}/.env"
              ''}
              cd "${statepath}"
              docker-compose ${value.args}
            '';
            ExecStopPost = pkgs.writeShellScript ("execstop-docker-compose-runner-" + name) ''
              set -e
              cd "${statepath}"
              docker-compose down
            '';
            Restart = "always";
            RestartSec = 5;
          };
          unitConfig = {
            After = "docker.service";
            StopPropagatedFrom = "docker.service";
            Requisite = "docker.service";
          };
        }
      ))
      cfg;
    virtualisation.docker.enable = mkIf (cfg != { }) true;
    environment.systemPackages = mkIf (cfg != { }) [ pkgs.docker-compose ];
  };
}
