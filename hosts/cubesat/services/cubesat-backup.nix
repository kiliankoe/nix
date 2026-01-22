# Restic backup for cubesat (pangolin service)
# Backs up to SFTP server using credentials from sops secrets
#
# Notifications: Uses healthchecks.io (or compatible) for dead man's switch alerts.
# Set cubesat_backup/healthcheck_url in sops to enable notifications.
#
# Restore: Use `cubesat-backup-restore` command (installed to system PATH)
#
# Pre-upgrade backups: Run `systemctl start cubesat-backup-preupgrade` before deployments
{ pkgs, ... }:

let
  # Paths to back up
  backupPaths = [
    "/var/lib/pangolin"
  ];

  # Common environment setup for both backup and restore
  setupEnvScript = ''
    # Read secrets
    SFTP_HOST=$(cat /run/secrets/cubesat_backup/server)
    SFTP_USER=$(cat /run/secrets/cubesat_backup/username)
    SFTP_PASS=$(cat /run/secrets/cubesat_backup/password)
    export RESTIC_PASSWORD=$(cat /run/secrets/cubesat_backup/restic_password)

    # Set up rclone SFTP backend via environment variables
    export RCLONE_CONFIG_BACKUP_TYPE=sftp
    export RCLONE_CONFIG_BACKUP_HOST="$SFTP_HOST"
    export RCLONE_CONFIG_BACKUP_USER="$SFTP_USER"
    export RCLONE_CONFIG_BACKUP_PASS=$(${pkgs.rclone}/bin/rclone obscure "$SFTP_PASS")

    REPO="rclone:backup:/backups/cubesat"
  '';

  backupScript = pkgs.writeShellScript "cubesat-backup" ''
    set -euo pipefail

    # Parse arguments
    TAGS=""
    while [[ $# -gt 0 ]]; do
      case $1 in
        --tag)
          TAGS="$TAGS --tag $2"
          shift 2
          ;;
        *)
          echo "Unknown argument: $1"
          exit 1
          ;;
      esac
    done

    echo "=== Cubesat backup started at $(date) ==="
    if [ -n "$TAGS" ]; then
      echo "Tags:$TAGS"
    fi

    # Notify healthcheck start (if configured)
    if [ -f /run/secrets/cubesat_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/cubesat_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/start" || true
    fi

    ${setupEnvScript}

    # Initialize repo if needed
    if ! ${pkgs.restic}/bin/restic -r "$REPO" snapshots &>/dev/null; then
      echo "Initializing restic repository..."
      ${pkgs.restic}/bin/restic -r "$REPO" init
    fi

    # Build list of paths to back up
    PATHS_TO_BACKUP=""

    echo "Checking backup paths..."
    for path in ${builtins.concatStringsSep " " (map (p: ''"${p}"'') backupPaths)}; do
      if [ -e "$path" ]; then
        PATHS_TO_BACKUP="$PATHS_TO_BACKUP $path"
        echo "  Will back up: $path"
      else
        echo "  Skipping (not found): $path"
      fi
    done

    if [ -z "$PATHS_TO_BACKUP" ]; then
      echo "ERROR: No paths to back up!"
      exit 1
    fi

    # Run backup
    echo "Running restic backup..."
    ${pkgs.restic}/bin/restic -r "$REPO" backup \
      --verbose \
      --exclude-caches \
      $TAGS \
      $PATHS_TO_BACKUP

    # Prune old snapshots (keep pre-upgrade tagged snapshots longer)
    echo "Pruning old snapshots..."
    ${pkgs.restic}/bin/restic -r "$REPO" forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --keep-tag pre-upgrade \
      --prune

    # Show backup stats
    echo "Current snapshots:"
    ${pkgs.restic}/bin/restic -r "$REPO" snapshots --latest 5

    echo "=== Cubesat backup completed at $(date) ==="

    # Notify healthcheck success (if configured)
    if [ -f /run/secrets/cubesat_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/cubesat_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL" || true
    fi
  '';

  # Restore helper script
  restoreScript = pkgs.writeShellScriptBin "cubesat-backup-restore" ''
    set -euo pipefail

    ${setupEnvScript}

    usage() {
      echo "Cubesat Backup Restore Tool"
      echo ""
      echo "Usage: cubesat-backup-restore <command> [options]"
      echo ""
      echo "Commands:"
      echo "  list                    List all snapshots"
      echo "  files <snapshot> [path] List files in a snapshot (optionally filter by path)"
      echo "  restore <snapshot>      Restore a snapshot to /var/restore/<snapshot-id>"
      echo "  shell                   Open interactive shell with restic configured"
      echo ""
      echo "Examples:"
      echo "  cubesat-backup-restore list"
      echo "  cubesat-backup-restore files latest"
      echo "  cubesat-backup-restore files latest /var/lib/pangolin"
      echo "  cubesat-backup-restore restore latest"
      echo ""
    }

    case "''${1:-}" in
      list)
        ${pkgs.restic}/bin/restic -r "$REPO" snapshots
        ;;
      files)
        SNAPSHOT="''${2:-latest}"
        FILTER_PATH="''${3:-}"
        ${pkgs.restic}/bin/restic -r "$REPO" ls "$SNAPSHOT" $FILTER_PATH
        ;;
      restore)
        SNAPSHOT="''${2:-latest}"
        RESTORE_DIR="/var/restore/$SNAPSHOT-$(date +%Y%m%d-%H%M%S)"
        echo "Restoring snapshot $SNAPSHOT to $RESTORE_DIR..."
        mkdir -p "$RESTORE_DIR"
        ${pkgs.restic}/bin/restic -r "$REPO" restore "$SNAPSHOT" --target "$RESTORE_DIR"
        echo ""
        echo "Restore complete. Files are in: $RESTORE_DIR"
        echo ""
        echo "To restore pangolin data:"
        echo "  1. Stop the service: sudo systemctl stop pangolin"
        echo "  2. Copy files: cp -r $RESTORE_DIR/var/lib/pangolin/* /var/lib/pangolin/"
        echo "  3. Start the service: sudo systemctl start pangolin"
        ;;
      shell)
        echo "Opening shell with restic configured..."
        echo "Repository: $REPO"
        echo ""
        echo "Example commands:"
        echo "  restic snapshots"
        echo "  restic ls latest"
        echo "  restic restore latest --target /tmp/restore"
        echo ""
        export REPO
        exec ${pkgs.bash}/bin/bash
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  '';

  # Notify on failure
  failureScript = pkgs.writeShellScript "cubesat-backup-failure" ''
    if [ -f /run/secrets/cubesat_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/cubesat_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/fail" || true
    fi
  '';

in
{
  # Install restore helper to system PATH
  environment.systemPackages = [ restoreScript ];

  # Ensure restore directory exists
  systemd.tmpfiles.rules = [
    "d /var/restore 0700 root root -"
  ];

  # Failure notification service
  systemd.services.cubesat-backup-failure = {
    description = "Notify backup failure";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = failureScript;
    };
  };

  # Main backup service (scheduled daily)
  systemd.services.cubesat-backup = {
    description = "Restic backup for cubesat";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Trigger failure notification if backup fails
    onFailure = [ "cubesat-backup-failure.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupScript;
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.cubesat-backup = {
    description = "Daily backup timer for cubesat";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "03:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  # Pre-upgrade backup service (triggered manually before deployments)
  systemd.services.cubesat-backup-preupgrade = {
    description = "Pre-upgrade backup for cubesat";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    onFailure = [ "cubesat-backup-failure.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${backupScript} --tag pre-upgrade";
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  # Sops secrets
  sops.secrets."cubesat_backup/server" = { };
  sops.secrets."cubesat_backup/username" = { };
  sops.secrets."cubesat_backup/password" = { };
  sops.secrets."cubesat_backup/restic_password" = { };
  sops.secrets."cubesat_backup/healthcheck_url" = { };
}
