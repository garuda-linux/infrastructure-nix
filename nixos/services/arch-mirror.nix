{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.services.garuda-arch-mirror;
in
{
  options.services.garuda-arch-mirror = {
    enable = mkEnableOption "Garuda Arch Linux mirror (rsync + rclone to R2)";
    upstreamUrl = mkOption {
      type = types.str;
      description = "rsync URL of a tier 1 Arch Linux mirror.";
    };
    lastupdateUrl = mkOption {
      type = types.str;
      description = "HTTP(S) URL pointing to the 'lastupdate' file on the mirror, used to skip rsync when nothing changed.";
    };
    localPath = mkOption {
      type = types.str;
      default = "/srv/http/arch-mirror";
      description = "Local directory holding the mirrored Arch Linux tree.";
    };
    tls = mkOption {
      type = types.bool;
      default = true;
      description = "Whether the upstream mirror supports rsync over TLS (rsync-ssl).";
    };
    bwlimit = mkOption {
      type = types.int;
      default = 0;
      description = "Limit bandwidth used by rsync in KiB/s. 0 disables the limit.";
    };
    rcloneConfig = mkOption {
      type = types.path;
      default = "/root/.config/rclone/rclone.conf";
      description = "Path to the rclone config (reuses the R2 keys).";
    };
    rcloneDest = mkOption {
      type = types.str;
      default = "r2:/mirror/arch";
      description = "rclone destination. The first path segment is the R2 bucket name, the rest is the path within it.";
    };
    rcloneArgs = mkOption {
      type = types.str;
      default = "-L --s3-upload-cutoff 5G --s3-chunk-size 4G --transfers 16 --checkers 16 --multi-thread-streams 4 --fast-list --s3-no-head --s3-no-check-bucket --ignore-checksum --s3-disable-checksum -u --use-server-modtime --size-only --delete-during --delete-excluded --stats=30s --stats-log-level NOTICE";
      description = "Extra rclone sync arguments. -L/--copy-links dereferences the Arch repo symlinks into real files on R2.";
    };
    startAt = mkOption {
      type = types.str;
      default = "hourly";
      description = "Poll interval. Arch tier-2 mirrors must not sync more than hourly.";
    };
    randomizedDelaySec = mkOption {
      type = types.int;
      default = 120;
      description = "Random delay to space out requests against the upstream mirror.";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.garuda-arch-mirror = {
      description = "Sync Arch Linux mirror from tier 1 and push changes to R2";
      path = [ pkgs.rsync pkgs.openssl pkgs.curl ];
      serviceConfig.Type = "oneshot";
      script = ''
        set -euo pipefail

        target="${cfg.localPath}"
        mkdir -p "$target"
        exec 9>"/tmp/arch-mirror-sync.lck"
        ${pkgs.flock}/bin/flock -n 9 || exit

        # Clean up any temporary files from old runs
        find "$target" -name '.~tmp~' -exec rm -r {} + 2>/dev/null || true

        rsync_cmd() {
          local cmd
          cmd=(${if cfg.tls then ''"${pkgs.rsync}/bin/rsync-ssl" --type=openssl'' else ''"${pkgs.rsync}/bin/rsync"''})
          cmd+=(-rlptH --copy-links --delete-delay --delay-updates --timeout=600 --no-motd)
          if stty &>/dev/null; then
            cmd+=(-h -v --progress)
          else
            cmd+=(--stats --info=name0)
          fi
          if (( ${toString cfg.bwlimit} > 0 )); then
            cmd+=("--bwlimit=${toString cfg.bwlimit}")
          fi
          "''${cmd[@]}" "$@"
        }
        export -f rsync_cmd

        # Only run when there are changes (non-interactive / cronjob case)
        if ! tty -s && [[ -f "$target/lastupdate" ]] && diff -b <(curl -Ls "${cfg.lastupdateUrl}") "$target/lastupdate" >/dev/null; then
          echo "No changes, updating lastsync timestamp only."
          rsync_cmd "${cfg.upstreamUrl}/lastsync" "$target/lastsync"
          exit 0
        fi

        echo "Changes detected, syncing from upstream."
        rsync_cmd \
          --exclude='*.links.tar.gz*' \
          --exclude='/other' \
          --exclude='/sources' \
          "${cfg.upstreamUrl}" \
          "$target"

        echo "Sync complete, pushing to R2."
        ${pkgs.flock}/bin/flock -w 60 /tmp/arch-mirror-rclone.lock \
          ${pkgs.rclone}/bin/rclone sync \
            --config="${cfg.rcloneConfig}" \
            "$target" "${cfg.rcloneDest}" ${cfg.rcloneArgs}
        echo "R2 sync finished."
      '';
    };

    systemd.timers.garuda-arch-mirror = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.startAt;
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = true;
      };
    };
  };
}
