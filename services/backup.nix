# Unified restic backup for all kepler services (native NixOS + Docker)
# Backs up to SFTP server using credentials from sops secrets
#
# Notifications: Uses healthchecks.io (or compatible) for dead man's switch alerts.
# Set kepler_backup/healthcheck_url in sops to enable notifications.
#
# Restore: Use `kepler-backup-restore` command (installed to system PATH)
{ config, pkgs, lib, ... }:

let
  # Static paths for native NixOS services
  staticBackupPaths = [
    "/var/lib/paperless"
    "/var/lib/uptime-kuma"
    "/var/backup/postgresql"
  ];

  # Docker volume names to back up (we query Docker for actual paths at runtime)
  # Format: patterns to match with `docker volume ls --filter`
  dockerVolumePatterns = [
    "wbbash"
    "linkding"
    "changedetection"
    "mato"
    "foundry"
    "lehmuese"
    "newsdiff"
  ];

  # Common environment setup for both backup and restore
  setupEnvScript = ''
    # Read secrets
    SFTP_HOST=$(cat /run/secrets/kepler_backup/server)
    SFTP_USER=$(cat /run/secrets/kepler_backup/username)
    SFTP_PASS=$(cat /run/secrets/kepler_backup/password)
    export RESTIC_PASSWORD=$(cat /run/secrets/kepler_backup/restic_password)

    # Set up rclone SFTP backend via environment variables
    export RCLONE_CONFIG_BACKUP_TYPE=sftp
    export RCLONE_CONFIG_BACKUP_HOST="$SFTP_HOST"
    export RCLONE_CONFIG_BACKUP_USER="$SFTP_USER"
    export RCLONE_CONFIG_BACKUP_PASS=$(${pkgs.rclone}/bin/rclone obscure "$SFTP_PASS")

    REPO="rclone:backup:/backups/kepler"
  '';

  backupScript = pkgs.writeShellScript "kepler-backup" ''
    set -euo pipefail

    echo "=== Kepler backup started at $(date) ==="

    # Notify healthcheck start (if configured)
    if [ -f /run/secrets/kepler_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/kepler_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/start" || true
    fi

    ${setupEnvScript}

    # Initialize repo if needed
    if ! ${pkgs.restic}/bin/restic -r "$REPO" snapshots &>/dev/null; then
      echo "Initializing restic repository..."
      ${pkgs.restic}/bin/restic -r "$REPO" init
    fi

    # Dump PostgreSQL databases
    echo "Dumping PostgreSQL databases..."
    mkdir -p /var/backup/postgresql
    for db in freshrss paperless; do
      if ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
        echo "  Dumping $db..."
        ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/pg_dump "$db" > "/var/backup/postgresql/$db.sql"
      else
        echo "  Skipping $db (database not found)"
      fi
    done

    # Build list of paths to back up
    PATHS_TO_BACKUP=""

    # Add static paths (native NixOS services)
    echo "Checking static backup paths..."
    for path in ${lib.concatMapStringsSep " " (p: ''"${p}"'') staticBackupPaths}; do
      if [ -e "$path" ]; then
        PATHS_TO_BACKUP="$PATHS_TO_BACKUP $path"
        echo "  Will back up: $path"
      else
        echo "  Skipping (not found): $path"
      fi
    done

    # Discover Docker volumes at runtime (more resilient than hardcoding paths)
    echo "Discovering Docker volumes..."
    for pattern in ${lib.concatMapStringsSep " " (p: ''"${p}"'') dockerVolumePatterns}; do
      # Find all volumes matching this pattern
      for volume in $(${pkgs.docker}/bin/docker volume ls --filter "name=$pattern" -q 2>/dev/null || true); do
        # Get the actual mountpoint from Docker
        mountpoint=$(${pkgs.docker}/bin/docker volume inspect "$volume" --format '{{.Mountpoint}}' 2>/dev/null || true)
        if [ -n "$mountpoint" ] && [ -e "$mountpoint" ]; then
          PATHS_TO_BACKUP="$PATHS_TO_BACKUP $mountpoint"
          echo "  Will back up Docker volume: $volume -> $mountpoint"
        fi
      done
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
      $PATHS_TO_BACKUP

    # Prune old snapshots
    echo "Pruning old snapshots..."
    ${pkgs.restic}/bin/restic -r "$REPO" forget \
      --keep-daily 7 \
      --keep-weekly 4 \
      --keep-monthly 6 \
      --prune

    # Show backup stats
    echo "Current snapshots:"
    ${pkgs.restic}/bin/restic -r "$REPO" snapshots --latest 5

    echo "=== Kepler backup completed at $(date) ==="

    # Notify healthcheck success (if configured)
    if [ -f /run/secrets/kepler_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/kepler_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL" || true
    fi
  '';

  # Restore helper script
  restoreScript = pkgs.writeShellScriptBin "kepler-backup-restore" ''
    set -euo pipefail

    ${setupEnvScript}

    usage() {
      echo "Kepler Backup Restore Tool"
      echo ""
      echo "Usage: kepler-backup-restore <command> [options]"
      echo ""
      echo "Commands:"
      echo "  list                    List all snapshots"
      echo "  files <snapshot> [path] List files in a snapshot (optionally filter by path)"
      echo "  restore <snapshot>      Restore a snapshot to /var/restore/<snapshot-id>"
      echo "  restore-db <snapshot>   Restore PostgreSQL databases from a snapshot"
      echo "  shell                   Open interactive shell with restic configured"
      echo ""
      echo "Examples:"
      echo "  kepler-backup-restore list"
      echo "  kepler-backup-restore files latest"
      echo "  kepler-backup-restore files latest /var/lib/paperless"
      echo "  kepler-backup-restore restore latest"
      echo "  kepler-backup-restore restore-db latest"
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
        echo "To restore specific services, copy files to their original locations:"
        echo "  - Paperless: cp -r $RESTORE_DIR/var/lib/paperless/* /var/lib/paperless/"
        echo "  - Uptime Kuma: cp -r $RESTORE_DIR/var/lib/uptime-kuma/* /var/lib/uptime-kuma/"
        echo "  - Docker volumes: cp -r $RESTORE_DIR/var/lib/docker/volumes/* /var/lib/docker/volumes/"
        echo ""
        echo "For PostgreSQL databases, use: kepler-backup-restore restore-db $SNAPSHOT"
        ;;
      restore-db)
        SNAPSHOT="''${2:-latest}"
        RESTORE_DIR=$(mktemp -d)
        echo "Extracting PostgreSQL dumps from snapshot $SNAPSHOT..."
        ${pkgs.restic}/bin/restic -r "$REPO" restore "$SNAPSHOT" \
          --target "$RESTORE_DIR" \
          --include "/var/backup/postgresql"

        echo ""
        for dump in "$RESTORE_DIR"/var/backup/postgresql/*.sql; do
          if [ -f "$dump" ]; then
            DB_NAME=$(basename "$dump" .sql)
            echo "Found dump for database: $DB_NAME"
            echo "  To restore, run:"
            echo "    sudo -u postgres psql $DB_NAME < $dump"
            echo ""
          fi
        done
        echo "Dumps extracted to: $RESTORE_DIR/var/backup/postgresql/"
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
  failureScript = pkgs.writeShellScript "kepler-backup-failure" ''
    if [ -f /run/secrets/kepler_backup/healthcheck_url ]; then
      HEALTHCHECK_URL=$(cat /run/secrets/kepler_backup/healthcheck_url)
      ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/fail" || true
    fi
  '';

in
{
  # Install restore helper to system PATH
  environment.systemPackages = [ restoreScript ];

  # Ensure backup/restore directories exist
  systemd.tmpfiles.rules = [
    "d /var/backup 0700 root root -"
    "d /var/backup/postgresql 0700 root root -"
    "d /var/restore 0700 root root -"
  ];

  # Failure notification service
  systemd.services.kepler-backup-failure = {
    description = "Notify backup failure";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = failureScript;
    };
  };

  systemd.services.kepler-backup = {
    description = "Restic backup for kepler";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    # Trigger failure notification if backup fails
    onFailure = [ "kepler-backup-failure.service" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupScript;
      Nice = 10;
      IOSchedulingClass = "idle";
    };
  };

  systemd.timers.kepler-backup = {
    description = "Daily backup timer for kepler";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "04:00";
      RandomizedDelaySec = "1h";
      Persistent = true;
    };
  };

  # Restic repository encryption password (required)
  sops.secrets."kepler_backup/restic_password" = { };

  # Healthcheck URL for notifications (optional - backup works without it)
  # Get a free URL from https://healthchecks.io
  sops.secrets."kepler_backup/healthcheck_url" = { };
}
