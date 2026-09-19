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
      user = "stefan";
      home = "/home/stefan";
      key = keys.stefan;
      units = [
        "compose-runner-firedragon.service"
        "docker.service"
      ];
      runners = {
        firedragon-runner = {
          source = ../../../compose/firedragon-runner;
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
