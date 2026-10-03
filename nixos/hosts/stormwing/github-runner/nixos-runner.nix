{ lib, pkgs, ... }:
let
  name = "stormwing-nixos";

  # Bind-mounted from the host's sops secret github-runner/stormwing-nixos
  tokenFile = "/var/.github-runner-nixos.token";

  # Lives on the persistent cache mount instead of the RAM-backed /run
  workDir = "/var/cache/github-runner/nixos-work";
in
# Only meant to run trusted code: nyx's check-pr-trust gate sets allow-unsafe-pr-checkout
# for fork PRs from collaborators/members/owners, users with write access, or PRs labelled
# safe-to-test. Actions/checkout refuses other fork PR heads before Nix runs.
{
  services.github-runners.${name} = {
    enable = true;
    inherit name tokenFile workDir;
    url = "https://github.com/chaotic-cx";
    tokenType = "access";
    ephemeral = true;
    replace = true;
    user = "github-runner";
    group = "github-runner";
    extraLabels = [
      "nixos"
      "nyxbuilder"
    ];

    # nyx's check-pr-trust action still uses the node20 github-script@v7,
    # but nixpkgs only ships node24 for the runner
    extraEnvironment = {
      FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
      ACTIONS_RUNNER_REQUIRE_JOB_CONTAINER = "true";
    };
    extraPackages = with pkgs; [
      curl
      docker
      jq
      openssh
    ];
    serviceOverrides = {
      PrivateUsers = false;
      ProtectProc = "default";
      PrivateTmp = false;
      ProtectControlGroups = false;
      ProtectSystem = "full";
    };
  };

  # Client-side only. Daemon settings (system-features, max-jobs) come from the host.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
    # Mirrors the host daemon, so `nix config show` in here reports what builds can use
    system-features = [
      "gccarch-x86-64-v3"
    ]
    ++ map (arch: "gccarch-${arch}") lib.systems.architectures.inferiors."x86-64-v3";
  };

  users = {
    groups.github-runner = { };
    users.github-runner = {
      isSystemUser = true;
      group = "github-runner";
      extraGroups = [ "docker" ];
      home = workDir;
    };
  };

  systemd.tmpfiles.rules = [ "d ${workDir} 0750 github-runner github-runner -" ];
}
