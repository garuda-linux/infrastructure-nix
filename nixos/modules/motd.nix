{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.motd;

  units = lib.concatMapStringsSep " " lib.escapeShellArg cfg.relevantUnits;

  servicesSection =
    if cfg.relevantUnits == [ ] then
      ''
        state="$(systemctl is-system-running 2>/dev/null || echo unknown)"
        echo "  System state:     $state"''
    else
      ''
        for unit in ${units}; do
          ustate="$(systemctl is-active "$unit" 2>/dev/null || true)"
          case "''${ustate:-unknown}" in
            active) echo "  $unit (active)" ;;
            failed) echo "  $unit (failed)" ;;
            *) echo "  -- $unit (''${ustate:-unknown})" ;;
          esac
        done'';

  initscript = pkgs.writeShellScript "motdscript" ''
    if [ "$USER" != nico ] && [ "$USER" != "package-deployer" ]; then
      echo "Logged as:          ''${USER:-$(whoami)}@$(hostname)"
      ${lib.optionalString (cfg.parentHost != null) ''echo "Host:               ${cfg.parentHost}"''}
      
      virt="baremetal"
      if [ -f /run/systemd/container ]; then
        virt="container ($(cat /run/systemd/container))"
      elif v="$(systemd-detect-virt 2>/dev/null)" && [ -n "$v" ] && [ "$v" != "none" ]; then
        virt="container ($v)"
      fi
      echo "Type:               $virt"
      
      ips="$(hostname -I 2>/dev/null | tr -s ' ' | sed 's/ *$//')"
      echo "IP addresses:       ''${ips:-unknown}"
      pub="$(curl -fs --max-time 2 https://ifconfig.me 2>/dev/null || true)"
      [ -n "$pub" ] && echo "Public IP address:  $pub"
      echo ""
      
      echo "Services:"
      ${servicesSection}
      
      ${lib.optionalString cfg.listDocker "
      echo \"\"
      echo \"Docker containers:\"
      timeout 3 docker ps --format '{{.Names}}|{{.Status}}' 2>/dev/null | while IFS='|' read -r dname dstatus; do
        echo \"  $dname ($dstatus)\"
      done
      stopped=\"$(timeout 3 docker ps -a -f status=exited -f status=created -f status=dead --format '{{.Names}}' 2>/dev/null | wc -l)\"
      [ \"$stopped\" -gt 0 ] && echo \"  ($stopped stopped)\""}

      echo -e ""
      echo -e "Please behave well and have fun! 🦅"
      echo -e "In case of issues or questions contact Nico or TNE."
    fi
    HISTCONTROL=ignoreboth
  '';
in
{
  options.garuda.motd = {
    parentHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Parent host name, shown on logins inside containers.";
    };
    relevantUnits = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Systemd units listed with their status on login.";
    };
    listDocker = lib.mkOption {
      type = lib.types.bool;
      default = config.virtualisation.docker.enable;
      description = "List docker containers and their status on login (defaults to whether docker is enabled).";
    };
  };

  config.environment.interactiveShellInit = "${initscript}";
}
