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

  parseCompose =
    file:
    let
      step =
        acc: line:
        let
          top = builtins.match "([A-Za-z_][A-Za-z0-9_-]*):.*" line;
          service = builtins.match "  ([A-Za-z0-9_.-]+):[[:space:]]*(#.*)?" line;
          image = builtins.match "    image:[[:space:]]*['\"]?([^'\" #]+).*" line;
          ports = builtins.match "    ports:[[:space:]]*\\[(.*)].*" line;
          update =
            attrs:
            acc
            // {
              services = acc.services // {
                ${acc.current} = acc.services.${acc.current} // attrs;
              };
            };
        in
        if top != null then
          acc
          // {
            inServices = head top == "services";
            current = null;
          }
        else if !acc.inServices then
          acc
        else if service != null then
          acc
          // {
            current = head service;
            services = acc.services // {
              ${head service} = {
                image = null;
                ports = [ ];
              };
            };
          }
        else if acc.current == null then
          acc
        else if image != null then
          update { image = head image; }
        else if ports != null then
          update {
            ports = map (replaceStrings [ "\"" "'" " " ] [ "" "" "" ]) (splitString "," (head ports));
          }
        else
          acc;
    in
    (foldl' step {
      inServices = false;
      current = null;
      services = { };
    } (splitString "\n" (builtins.readFile file))).services;

  # Icons for images we run, first match on the image name wins
  icons = pkgs.callPackage ../../topology-icons.nix { };
  imageIcons = [
    [
      "chaotic"
      "${icons.arch-linux}"
    ]
    [
      "matterbridge"
      "${icons.matterbridge}"
    ]
    [
      "nextcloud"
      "services.nextcloud"
    ]
    [
      "vaultwarden"
      "services.vaultwarden"
    ]
    [
      "syncserver"
      "services.firefox-syncserver"
    ]
    [
      "searxng"
      "services.searxng"
    ]
    [
      "redlib"
      "services.redlib"
    ]
    [
      "whoogle"
      "${icons.google}"
    ]
    [
      "lingva"
      "${icons.google-translate}"
    ]
    [
      "privatebin"
      "${icons.privatebin}"
    ]
    [
      "watchtower"
      "${icons.watchtower}"
    ]
    [
      "requarks/wiki"
      "${icons.wikijs}"
    ]
    [
      "redis"
      "${icons.redis}"
    ]
    [
      "gitlab-runner"
      "${icons.gitlab}"
    ]
    [
      "github-runner"
      "${icons.github-light}"
    ]
  ];
  iconFor =
    image:
    let
      matches = filter (pair: image != null && hasInfix (head pair) image) imageIcons;
    in
    if matches == [ ] then null else last (head matches);
in
{
  options.garuda.services.compose-runner = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          source = mkOption {
            type = types.path;
            description = "Folder containing a compose file.";
          };
          extraFiles = mkOption {
            type = types.listOf (types.either types.path filesType);
            description = "Extra files that will be copied to the compose file directory";
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
            description = "Additional arguments to pass to docker compose up";
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
              sed -r 's/(^\s+restart:\s*)(unless-stopped|always)(\s*($|#))/\1on-failure\3/g' "$src/compose.yml" > "$out/compose.yml"
              rsync --exclude="/compose.yml" -a "$src/" "$out"
            '';
            inherit (pkgs.stdenv.hostPlatform) system;
          };
          statepath = "/var/garuda/compose-runner/${name}";
        in
        {
          wantedBy = [ "multi-user.target" ];
          description = "Compose runner for ${name}";
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
              rsync -a --no-owner --checksum "${output}/" "${statepath}"
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

    topology.self.services = mkMerge (
      mapAttrsToList (
        stack: value:
        mapAttrs' (
          service: spec:
          nameValuePair "docker-${service}" {
            name = service;
            info = if spec.image == null then "" else spec.image;
            icon = iconFor spec.image;
            details = {
              stack.text = "compose-runner-${stack}";
            }
            // optionalAttrs (spec.ports != [ ]) {
              ports.text = concatLines spec.ports;
            };
          }
        ) (parseCompose "${value.source}/compose.yml")
      ) cfg
    );

    virtualisation.docker.enable = mkIf (cfg != { }) true;
    environment.systemPackages = mkIf (cfg != { }) [ pkgs.docker-compose ];
  };
}
