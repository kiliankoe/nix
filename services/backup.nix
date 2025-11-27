# Unified restic backup for all kepler services (native NixOS + Docker)
# Backs up to SFTP server using credentials from sops secrets
{ config, pkgs, lib, ... }:

let
  # Docker Compose volume naming: <project>_<volume>
  # Project name is the directory name in /etc/docker-compose/
  dockerVolume = project: volume: "/var/lib/docker/volumes/${project}_${volume}/_data";

  backupPaths = [
    # Native NixOS services
    "/var/lib/paperless"
    "/var/lib/uptime-kuma"

    # PostgreSQL dumps (created by backupPrepareCommand)
    "/var/backup/postgresql"

    # Docker Compose volumes
    (dockerVolume "wbbash" "wbbash-db")
    (dockerVolume "linkding" "linkding-data")
    (dockerVolume "changedetection" "changedetection-data")
    (dockerVolume "mato" "mato-data")
    (dockerVolume "foundry-vtt" "foundry-data")
    (dockerVolume "lehmuese-ics" "lehmuese-ics-db")
  ];

  backupScript = pkgs.writeShellScript "kepler-backup" ''
    set -euo pipefail

    echo "=== Kepler backup started at $(date) ==="

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

    # Build list of existing paths to back up
    PATHS_TO_BACKUP=""
    for path in ${lib.concatMapStringsSep " " (p: ''"${p}"'') backupPaths}; do
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
  '';

in
{
  # Ensure backup directories exist
  systemd.tmpfiles.rules = [
    "d /var/backup 0700 root root -"
    "d /var/backup/postgresql 0700 root root -"
  ];

  systemd.services.kepler-backup = {
    description = "Restic backup for kepler";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

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

  # Restic repository encryption password
  sops.secrets."kepler_backup/restic_password" = { };
}
