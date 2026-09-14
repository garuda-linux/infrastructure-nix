{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.garuda-gitlab-runner;

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
            nix-dind = {
              enable = lib.mkEnableOption "Nix caching with docker:dind image";
            };
            dind = {
              enable = lib.mkEnableOption "Docker-in-Docker support (privileged mode)";
            };
            kvm = {
              enable = lib.mkEnableOption "KVM passthrough (/dev/kvm, implies privileged)";
            };
          };
        }
      );
    };
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkIf (lib.any (
      r: r.nix-caching.enable || r.dind.enable || r.nix-dind.enable
    ) (lib.attrValues cfg.runners)) true;

    virtualisation.docker.enable = lib.mkIf (lib.any (
      r: r.nix-caching.enable || r.dind.enable || r.nix-dind.enable
    ) (lib.attrValues cfg.runners)) true;
    virtualisation.docker.daemon.settings.dns = lib.mkDefault config.networking.nameservers;

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
        }
        // (
          if r.nix-dind.enable then
            {
              dockerImage = "docker:29-cli";
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
                    "nix-dind"
                  ]
                  ++ r.tagList
                else
                  [ ];
            }
          else if r.nix-caching.enable then
            {
              dockerImage = "alpine";
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
              dockerImage = if r.dind.enable then "docker:29-cli" else "alpine";
              dockerPrivileged = r.dind.enable || r.kvm.enable;
              dockerVolumes =
                if r.dind.enable then
                  [
                    "/certs/client"
                    "/cache"
                  ]
                else
                  [ ] ++ lib.optionals r.kvm.enable [ "/dev/kvm:/dev/kvm" ];
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
  };
}
