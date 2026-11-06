{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.garuda-gitlab-runner;

  # renovate: datasource=docker depName=docker
  dindImage = "docker:29.9.0-cli";
  # renovate: datasource=docker depName=alpine
  jobImage = "alpine:3.24.4";

  nixVolumes = [
    "/nix/store:/nix/store:ro"
    "/nix/var/nix/db:/nix/var/nix/db:ro"
    "/nix/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro"
  ];
  nixEnvVars = {
    NIX_CONFIG = "experimental-features = nix-command flakes";
    NIX_REMOTE = "daemon";
    NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
    USER = "root";
  };
  nixContainerSetup = ''
    mkdir -p -m 0755 /nix/var/log/nix/drvs
    mkdir -p -m 0755 /nix/var/nix/gcroots
    mkdir -p -m 0755 /nix/var/nix/profiles
    mkdir -p -m 0755 /nix/var/nix/temproots
    mkdir -p -m 0755 /nix/var/nix/userpool
    mkdir -p -m 1777 /nix/var/nix/gcroots/per-user
    mkdir -p -m 1777 /nix/var/nix/profiles/per-user
    mkdir -p -m 0755 /nix/var/nix/profiles/per-user/root
    mkdir -p -m 0700 "$HOME/.nix-defexpr"

    if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  '';
  commonPreBuildScript = pkgs.writeScript "setup-container" ''
    ${nixContainerSetup}

    # Ensure we don't break the original PATH which contains gitlab-runner binaries
    export PATH="$PATH:/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin"

    . ${pkgs.nix}/etc/profile.d/nix-daemon.sh
    ${pkgs.nix}/bin/nix-channel --add https://nixos.org/channels/nixos-unstable nixpkgs
    ${pkgs.nix}/bin/nix-channel --update nixpkgs
    ${pkgs.nix}/bin/nix-env -i ${
      lib.concatStringsSep " " (
        with pkgs;
        [
          nix
          cacert
          git
          openssh
        ]
      )
    }
  '';

  dockerDataRoot = "/var/lib/docker";
  volumeCleanupScript = pkgs.writeShellApplication {
    name = "gitlab-runner-volume-cleanup";
    runtimeInputs = [
      config.virtualisation.docker.package
      pkgs.coreutils
    ];
    text = ''
      free_percent() {
        used=$(df --output=pcent ${dockerDataRoot} | tail -n 1 | tr -dc '0-9')
        echo $((100 - used))
      }

      min_free=${toString cfg.volumeCleanup.minFreePercent}
      target_free=${toString cfg.volumeCleanup.targetFreePercent}
      cutoff=$(date -d "-${toString cfg.volumeCleanup.maxVolumeAgeDays} days" +%s)

      free=$(free_percent)
      if [ "$free" -ge "$min_free" ]; then
        echo "$free% free, at least $min_free% required, nothing to do"
        exit 0
      fi
      echo "$free% free, below $min_free%, removing old volumes oldest first until $target_free% is free"

      # oldest first, so the most recent caches are the last to go
      docker volume ls -q | while read -r name; do
        created=$(docker volume inspect --format '{{.CreatedAt}}' "$name")
        if [ -n "$created" ]; then
          ts=$(date -d "$created" +%s) || continue
        else
          mountpoint=$(docker volume inspect --format '{{.Mountpoint}}' "$name")
          ts=$(stat -c %Y "$mountpoint") || continue
        fi
        echo "$ts $name"
      done | sort -n | while read -r ts name; do
        if [ "$ts" -ge "$cutoff" ]; then
          echo "no volumes left older than ${toString cfg.volumeCleanup.maxVolumeAgeDays} days"
          break
        fi
        free=$(free_percent)
        if [ "$free" -ge "$target_free" ]; then
          echo "$free% free, reached $target_free%"
          break
        fi
        if docker volume rm "$name" > /dev/null; then
          echo "removed $name"
        else
          echo "skipped $name, still in use"
        fi
      done
      echo "$(free_percent)% free after cleanup"
    '';
  };

  # Privileged jobs can't run in the remapped user namespace.
  # They opt out with --docker-userns host and stay root, so only protected jobs may use them.
  isPrivileged = r: r.nix-privileged.enable || r.dind.enable || r.kvm.enable;
in
{
  options.services.garuda-gitlab-runner = {
    enable = lib.mkEnableOption "GitLab Runner";

    listenAddress = lib.mkOption {
      default = "[::]:9252";
      type = lib.types.str;
      description = "Address for GitLab Runner to listen on (metrics and API).";
    };

    runners = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            authenticationTokenConfigFile = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path to the authentication token configuration file";
            };
            tagList = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
            dockerExtraHosts = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Custom host-to-IP mappings for Docker executor containers.";
            };
            nix-caching = {
              enable = lib.mkEnableOption "Nix caching for Docker executor";
            };
            nix-privileged = {
              enable = lib.mkEnableOption "Nix caching with docker:dind image, privileged and root (no user namespace remapping)";
            };
            dind = {
              enable = lib.mkEnableOption "Docker-in-Docker support (privileged mode)";
            };
            kvm = {
              enable = lib.mkEnableOption "KVM passthrough (/dev/kvm, implies privileged and no user namespace remapping)";
            };
          };
        }
      );
    };

    volumeCleanup = {
      enable = lib.mkEnableOption "removal of old docker volumes when storage is low, checked every 30 minutes";
      minFreePercent = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 15;
        description = "Start cleaning when less than this percent of the docker data root is free.";
      };
      targetFreePercent = lib.mkOption {
        type = lib.types.ints.between 0 100;
        default = 25;
        description = "Stop cleaning once this percent of the docker data root is free again.";
      };
      maxVolumeAgeDays = lib.mkOption {
        type = lib.types.ints.positive;
        default = 3;
        description = "Only volumes created more than this many days ago are removed.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.volumeCleanup.targetFreePercent >= cfg.volumeCleanup.minFreePercent;
        message = "services.garuda-gitlab-runner.volumeCleanup.targetFreePercent must not be below minFreePercent";
      }
      {
        assertion = !cfg.volumeCleanup.enable || config.virtualisation.docker.enable;
        message = "services.garuda-gitlab-runner.volumeCleanup needs docker, enable a runner with docker support";
      }
    ];

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkIf (lib.any (
      r: r.nix-caching.enable || r.dind.enable || r.nix-privileged.enable
    ) (lib.attrValues cfg.runners)) true;

    virtualisation.docker.enable = lib.mkIf (lib.any (
      r: r.nix-caching.enable || r.dind.enable || r.nix-privileged.enable
    ) (lib.attrValues cfg.runners)) true;
    virtualisation.docker.daemon.settings.dns = lib.mkDefault config.networking.nameservers;

    # Container root maps to an unprivileged host uid. Jobs that mount the
    # nix-daemon socket then connect as untrusted users, not as root.
    # Privileged runners opt out with --docker-userns host (see isPrivileged).
    virtualisation.docker.daemon.settings.userns-remap = "dockremap";
    users.users.dockremap = {
      isSystemUser = true;
      group = "dockremap";
      subUidRanges = [
        {
          startUid = 100000;
          count = 65536;
        }
      ];
      subGidRanges = [
        {
          startGid = 100000;
          count = 65536;
        }
      ];
    };
    users.groups.dockremap = { };

    services.gitlab-runner = {
      enable = true;
      settings = {
        concurrent = lib.max 4 ((2 * lib.length (lib.attrNames cfg.runners)) + 1);
        listen_address = cfg.listenAddress;
        metrics = {
          enable = true;
          port = 9252;
          portName = "metrics";
        };
      };
      services = lib.mapAttrs (
        _name: r:
        {
          inherit (r) authenticationTokenConfigFile;
          requestConcurrency = 4;
          executor = "docker";
          inherit (r) dockerExtraHosts;
          registrationFlags = lib.optional (isPrivileged r) "--docker-userns host";
        }
        // (
          if r.nix-privileged.enable then
            {
              dockerImage = dindImage;
              dockerPrivileged = true;
              dockerVolumes =
                nixVolumes
                ++ [
                  "/certs/client"
                  "/cache"
                ]
                ++ lib.optionals r.kvm.enable [ "/dev/kvm:/dev/kvm" ];
              preBuildScript = commonPreBuildScript;
              environmentVariables = nixEnvVars // {
                DOCKER_TLS_CERTDIR = "/certs";
                DOCKER_HOST = "tcp://docker:2376";
                DOCKER_TLS_VERIFY = "1";
                DOCKER_CERT_PATH = "/certs/client";
              };
              tagList =
                if r.authenticationTokenConfigFile == null then
                  [
                    "nix-privileged"
                  ]
                  ++ r.tagList
                else
                  [ ];
            }
          else if r.nix-caching.enable then
            {
              dockerImage = jobImage;
              dockerVolumes = nixVolumes ++ lib.optionals r.kvm.enable [ "/dev/kvm:/dev/kvm" ];
              dockerPrivileged = r.kvm.enable;
              dockerDisableCache = true;
              preBuildScript = commonPreBuildScript;
              environmentVariables = nixEnvVars // {
                ENV = "/etc/profile";
              };
              tagList = if r.authenticationTokenConfigFile == null then [ "nix" ] ++ r.tagList else [ ];
            }
          else
            {
              dockerImage = if r.dind.enable then dindImage else jobImage;
              dockerPrivileged = r.dind.enable || r.kvm.enable;
              dockerVolumes =
                if r.dind.enable then
                  [
                    "/certs/client"
                    "/cache"
                  ]
                else
                  lib.optionals r.kvm.enable [ "/dev/kvm:/dev/kvm" ];
              tagList = if r.authenticationTokenConfigFile == null then r.tagList else [ ];
            }
        )
      ) cfg.runners;
    };

    services.gitlab-runner.clear-docker-cache = {
      dates = "daily";
      enable = true;
      flags = [ "prune-volumes" ];
    };

    systemd.services.gitlab-runner-volume-cleanup = lib.mkIf cfg.volumeCleanup.enable {
      description = "Remove old docker volumes while storage is low";
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = lib.getExe volumeCleanupScript;
      };
    };
    systemd.timers.gitlab-runner-volume-cleanup = lib.mkIf cfg.volumeCleanup.enable {
      description = "Check docker storage every 30 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "*:0/30";
        Persistent = true;
      };
    };
  };
}
