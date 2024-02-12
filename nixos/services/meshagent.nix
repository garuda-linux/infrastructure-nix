{ config
, lib
, pkgs
, ...
}:
with lib;
let
  cfg = config.services.garuda-meshagent;
  meshagent = pkgs.stdenvNoCC.mkDerivation {
    src = cfg.agentBinary;
    name = "meshagent_patched";
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    installPhase = ''
      install -Dm755 "$src" "$out/meshagent"
    '';
    dontBuild = true;
    dontConfigure = true;
    dontUnpack = true;
  };
in
{
  options.services.garuda-meshagent = {
    enable = mkEnableOption "Garuda Meshagent";
    mshFile = mkOption { };
    agentBinary = mkOption { };
  };

  config = mkIf cfg.enable {
    systemd.services.meshagent = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      description = "meshagent background service";
      path = [ pkgs.wget pkgs.mount ];
      serviceConfig = {
        CacheDirectory = "meshagent";
        CacheDirectoryMode = "0755";
        PrivateMounts = "true";
        ExecStart = pkgs.writeShellScript "execstart" ''
          set -e
          cd "''${CACHE_DIRECTORY}"
          cp "${meshagent}/meshagent" ./meshagent
          if [ ! -f ./meshagent.msh ]; then cp "${cfg.mshFile}" ./meshagent.msh; fi
          mount --bind /run/current-system/sw/bin /bin
          ./meshagent
        '';
        Restart = "on-failure";
        RestartSec = "30";
      };
    };
  };
}
