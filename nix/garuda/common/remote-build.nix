{ config, lib, garuda-lib, ... }:
with lib;
let
  cfg = config.services.garuda-nix-builder;
in {
  options.services.garuda-nix-builder = {
    isBuilder = mkOption {
      type = types.bool;
      default = false;
    };
    host = mkOption {
      type = types.str;
    };
  };
  config = {
    users.users.nix-builder = mkIf cfg.isBuilder {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [ garuda-lib.secrets.ssh.team.public ];
    };
    nix.distributedBuilds = mkIf (!cfg.isBuilder) true;
    nix.buildMachines = [ {
      hostName = "nix-builder";
	    system = "x86_64-linux";
      maxJobs = 4;
      sshKey = garuda-lib.secrets.ssh.team.private;
      mandatoryFeatures = [ "big-parallel" ];
    } ];
    nix.settings.trusted-users = mkIf cfg.isBuilder [ "nix-builder" ];
    services.cachix-watch-store.enable = mkIf cfg.isBuilder true;
    services.cachix-watch-store.cachixTokenFile = garuda-lib.secrets.cachix;
    services.cachix-watch-store.cacheName = "garuda-linux";
    programs.ssh.extraConfig = ''
Host nix-builder
  HostName ${cfg.host}
  User nix-builder
  StrictHostKeyChecking no
  '';
  };
}
