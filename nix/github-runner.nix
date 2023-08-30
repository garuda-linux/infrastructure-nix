{ garuda-lib
, lib
, sources
, pkgs
, ...
}: {
  # No default modules, untrusted container!
  # imports = sources.defaultModules ++ [
  #   ./garuda/garuda.nix
  # ];

  users.users.runner = {
    isNormalUser = true;
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = 8;
    substituters = [ "https://nyx.chaotic.cx" ];
    trusted-public-keys = [
      "nyx.chaotic.cx-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
      "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="
    ];
  };

  services.github-runner = {
    enable = true;
    user = "runner";
    url = "https://github.com/chaotic-cx";
    tokenFile = "/var/garuda/secrets/github-runner-pat";
    name = "immortalis";
    extraLabels = [ "nyxbuilder" ];
    replace = true;
    serviceOverrides = {
      DynamicUser = lib.mkForce false;
    };
  };
  
  nixpkgs.config.permittedInsecurePackages = [
    "nodejs-16.20.2"
  ];

  system.stateVersion = "23.05";
}
