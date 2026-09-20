{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.garuda.motd;

  fastfetchConfig = (pkgs.formats.json { }).generate "fastfetch-motd.json" {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    display.separator = ": ";
    modules = [
      "title"
      "separator"
      "os"
      {
        type = "kernel";
        format = "{sysname} {release}";
      }
      "uptime"
      {
        type = "packages";
        combined = true;
      }
      "cpu"
      {
        type = "gpu";
        format = "{name}";
      }
      {
        type = "memory";
        format = "{used} / {total} ({percentage})";
      }
      {
        type = "disk";
        folders = [
          "/"
          "/data_1"
          "/data_2"
        ];
        format = "{size-used} / {size-total} ({size-percentage}) - {filesystem}";
      }
      {
        type = "localip";
        showIpv6 = false;
        showLoopback = false;
        defaultRouteOnly = false;
      }
      {
        type = "publicip";
        timeout = 2000;
      }
      "break"
      {
        type = "command";
        key = "System state";
        text = "state=$(systemctl is-system-running 2>/dev/null); echo \${state:-unknown}";
      }
      {
        type = "command";
        key = "Failed units";
        text = "failed=$(systemctl list-units --state=failed --no-legend --plain 2>/dev/null | awk 'NF{print $1}' | paste -sd' ' -); echo \${failed:-none}";
      }
      {
        type = "command";
        key = "System type";
        text = ''
          if [ -f /run/systemd/container ]; then echo "container ($(cat /run/systemd/container))"; else v=$(systemd-detect-virt 2>/dev/null); if [ -n "$v" ] && [ "$v" != "none" ]; then echo "container ($v)"; else echo baremetal; fi; fi'';
      }
      {
        type = "command";
        key = "Last update";
        text = ''
          if [ -f /run/systemd/container ]; then exit 0; fi; date -d @$(stat -c %Y /run/current-system 2>/dev/null || date +%s) '+%Y-%m-%d %H:%M'';
      }
    ]
    ++ lib.optional (cfg.parentHost != null) {
      type = "command";
      key = "Parent host";
      text = "echo ${cfg.parentHost}";
    }
    ++ lib.optional config.virtualisation.docker.enable {
      type = "command";
      key = "Docker";
      text = ''run=$(timeout 3 docker ps -q 2>/dev/null | wc -l); all=$(timeout 3 docker ps -aq 2>/dev/null | wc -l); bad=$(timeout 3 docker ps -f status=exited -f status=dead -f status=created --format '{{.Names}}' 2>/dev/null | paste -sd',' -); unh=$(timeout 3 docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | paste -sd',' -); msg="$run running, $((all - run)) stopped"; extra="$bad,$unh"; extra=$(echo "$extra" | tr ',' '\n' | awk 'NF' | paste -sd',' -); if [ -n "$extra" ]; then echo "$msg | $extra"; else echo "$msg"; fi'';
    };
  };
in
{
  options.garuda.motd.parentHost = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Parent host name, shown on logins inside containers.";
  };

  config = {
    environment.systemPackages = [ pkgs.fastfetch ];

    environment.etc."fastfetch-motd.json".source = fastfetchConfig;

    environment.interactiveShellInit = "${pkgs.writeShellScript "motdscript" ''
      ${lib.getExe pkgs.fastfetch} --config /etc/fastfetch-motd.json
      echo ""
      echo "        Please behave well and have fun! In case of issues contact Nico or TNE 🦅"
      HISTCONTROL=ignoreboth
    ''}";
  };
}
