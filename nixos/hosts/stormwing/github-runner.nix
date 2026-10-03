{
  garuda-lib,
  inputs,
  keys,
  ...
}:
{
  # No default modules, untrusted container!
  imports = [
    inputs.nix-topology.nixosModules.default
    inputs.sops-nix.nixosModules.sops
    ../../modules/garuda-lib.nix
    ../../modules/hardening.nix
    ../../modules/motd.nix
    ../../modules/topology.nix
    ../../services/compose-runner/compose-runner.nix
    ../../services/mk.nix
    ../../services/monitoring
    ./github-runner/nixos-runner.nix
  ];

  inherit
    (garuda-lib.mkUntrustedRunner {
      user = "pedrohlc";
      home = "/home/pedrohlc";
      key = keys.pedrohlc;
      units = [
        "github-runner-stormwing-nixos.service"
        "docker.service"
      ];
      runners = {
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
