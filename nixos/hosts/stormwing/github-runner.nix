{
  garuda-lib,
  inputs,
  keys,
  ...
}:
{
  # No default modules, untrusted container!
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../../modules/garuda-lib.nix
    ../../modules/hardening.nix
    ../../modules/motd.nix
    ../../services/compose-runner/compose-runner.nix
    ../../services/mk.nix
    ../../services/monitoring
  ];

  inherit
    (garuda-lib.mkUntrustedRunner {
      user = "pedrohlc";
      home = "/home/pedrohlc";
      key = keys.pedrohlc;
      units = [
        "compose-runner-github-runner.service"
        "docker.service"
      ];
      runners = {
        github-runner = {
          envfile = "/var/.github-runner.env";
          source = ../../../compose/github-runner;
        };
        gitlab-runner = {
          source = ../../../compose/gitlab-runner;
        };
      };
    })
    garuda
    nix
    security
    services
    systemd
    users
    virtualisation
    ;

  system.stateVersion = "25.05";
}
