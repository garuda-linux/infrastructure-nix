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
    trusted-users = [ "runner" ];
    experimental-features = [ "nix-command" "flakes" ];
    accept-flake-config = true;
    max-jobs = 8;
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
