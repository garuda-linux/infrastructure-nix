{ pkgs, ... }:
let
  name = "stormwing-nixos";

  # Bind-mounted from the host's sops secret github-runner/stormwing-nixos
  tokenFile = "/var/.github-runner-nixos.token";

  # Lives on the persistent cache mount instead of the RAM-backed /run
  workDir = "/var/cache/github-runner/nixos-work";
in
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
    extraEnvironment.FORCE_JAVASCRIPT_ACTIONS_TO_NODE24 = "true";
    extraPackages = with pkgs; [
      curl
      jq
      openssh
    ];
  };

  users = {
    groups.github-runner = { };
    users.github-runner = {
      isSystemUser = true;
      group = "github-runner";
      home = workDir;
    };
  };

  systemd.tmpfiles.rules = [ "d ${workDir} 0750 github-runner github-runner -" ];
}
