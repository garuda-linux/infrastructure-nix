{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.garuda.services.compose-runner;
  filesType = types.submodule {
    options = {
      targetFileName = mkOption {
        type = types.str;
      };
      file = mkOption {
        type = types.path;
      };
      noClobber = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
in
{
  options.garuda.services.compose-runner = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          source = mkOption {
            type = types.path;
            description = "Folder containing a docker-compose file.";
          };
          extraFiles = mkOption {
            type = types.listOf (types.either types.path filesType);
            description = "Extra files that will be copied to the docker-compose file directory";
            default = [ ];
          };
          extraEnv = mkOption {
            type = types.attrsOf types.str;
            description = "Extra env variables that are visible in the nix store";
            default = { };
          };
          envfile = mkOption {
            type = types.nullOr types.path;
            description = "Direct path to a valid .env file";
            default = null;
          };
          args = mkOption {
            type = types.str;
            description = "Additional arguments to pass to docker-compose up";
            default = "up --remove-orphans --force-recreate";
          };
        };
      }
    );
    default = { };
  };

  config = {
    systemd.services = mapAttrs' (
      name: value:
      nameValuePair ("compose-runner-" + name) (
        let
          output = derivation {
            name = "compose-runner-" + name;
            src = value.source;
            builder = pkgs.writeShellScript "build" ''
              PATH="${pkgs.rsync}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin"
              set -e
              mkdir "$out"
              sed -r 's/(^\s+restart:\s*)(unless-stopped|always)(\s*($|#))/\1on-failure\3/g' "$src/docker-compose.yml" > "$out/docker-compose.yml"
              rsync --exclude="/docker-compose.yml" -a "$src/" "$out"
            '';
            inherit (pkgs.hostPlatform) system;
          };
          statepath = "/var/garuda/compose-runner/${name}";
        in
        {
          wantedBy = [ "multi-user.target" ];
          description = "docker-compose runner for ${name}";
          path = with pkgs; [
            rsync
            docker-compose
            docker
            bash
          ];
          startLimitIntervalSec = 30;
          startLimitBurst = 3;
          serviceConfig = {
            ExecStart = pkgs.writeShellScript ("execstart-compose-runner-" + name) ''
              set -e
              mkdir -p "${statepath}"
              rsync -a --no-owner --size-only "${output}/" "${statepath}"
              ${optionalString (value.envfile != null) ''
                cp "${value.envfile}" "${statepath}/.env"
                chmod 600 "${statepath}/.env"
              ''}
              ${concatMapStringsSep "\n" (
                x:
                if isAttrs x then
                  ''cp ${optionalString x.noClobber "--update=none "}"${x.file}" "${statepath}/${x.targetFileName}"''
                else
                  ''cp ${optionalString x.noClobber "--update=none "}"${x}" "${statepath}/"''
              ) value.extraFiles}
              cd "${statepath}"
              docker compose ${value.args}
            '';
            ExecStopPost = pkgs.writeShellScript ("execstop-compose-runner-" + name) ''
              set -e
              cd "${statepath}"
              docker compose down --remove-orphans
            '';
            Restart = "always";
            RestartSec = 5;
          };
          unitConfig = {
            After = "docker.service";
            StopPropagatedFrom = "docker.service";
            Requisite = "docker.service";
          };
          environment = value.extraEnv;
        }
      )
    ) cfg;
    virtualisation.docker.enable = mkIf (cfg != { }) true;
    environment.systemPackages = mkIf (cfg != { }) [ pkgs.docker-compose ];
  };
}
