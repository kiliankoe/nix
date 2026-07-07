# Shared restic backup + restore tooling for hosts backing up to the SFTP
# server. Both hosts end up with identically named systemd units
# (restic-backup, restic-backup-preupgrade, restic-backup-failure) and the
# same restore CLI (`backup-restore`), so operating either host works the
# same way regardless of which one you're on.
{ pkgs, lib }:
let
  yamlEscape = p: ''"${p}"'';
in
{
  # hostName: used for the repo path (rclone:backup:/backups/<hostName>) and
  #   the sops secret prefix (<hostName>_backup/*)
  # onCalendar: systemd OnCalendar string for the daily backup timer
  # staticPaths: filesystem paths that are backed up if present
  # dockerVolumePatterns: Docker volume name patterns to discover and back up
  # postgresDatabases: PostgreSQL databases to pg_dump before each backup;
  #   also enables the `restore-db` and PostgreSQL-load steps of `verify`
  # restoreHints: extra lines printed after a `restore`, e.g. per-service
  #   copy-back instructions
  mkResticBackupService =
    {
      hostName,
      onCalendar,
      staticPaths ? [ ],
      dockerVolumePatterns ? [ ],
      postgresDatabases ? [ ],
      restoreHints ? [ ],
    }:
    let
      secretPrefix = "${hostName}_backup";
      hasPostgres = postgresDatabases != [ ];
      hasDockerVolumes = dockerVolumePatterns != [ ];

      # Common environment setup for both backup and restore
      setupEnvScript = ''
        # Read secrets
        SFTP_HOST=$(cat /run/secrets/${secretPrefix}/server)
        SFTP_USER=$(cat /run/secrets/${secretPrefix}/username)
        SFTP_PASS=$(cat /run/secrets/${secretPrefix}/password)
        export RESTIC_PASSWORD=$(cat /run/secrets/${secretPrefix}/restic_password)

        # systemd services run without $HOME; restic 0.19+ treats a missing cache
        # directory as a fatal error (older versions only warned), so point it at a
        # stable cache path explicitly. restic creates the dir if absent.
        export RESTIC_CACHE_DIR=/var/cache/restic

        # Set up rclone SFTP backend via environment variables
        export RCLONE_CONFIG_BACKUP_TYPE=sftp
        export RCLONE_CONFIG_BACKUP_HOST="$SFTP_HOST"
        export RCLONE_CONFIG_BACKUP_USER="$SFTP_USER"
        export RCLONE_CONFIG_BACKUP_PASS=$(${pkgs.rclone}/bin/rclone obscure "$SFTP_PASS")

        REPO="rclone:backup:/backups/${hostName}"
      '';

      backupScript = pkgs.writeShellScript "restic-backup" ''
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

        echo "=== ${hostName} backup started at $(date) ==="
        if [ -n "$TAGS" ]; then
          echo "Tags:$TAGS"
        fi

        # Notify healthcheck start (if configured)
        if [ -f /run/secrets/${secretPrefix}/healthcheck_url ]; then
          HEALTHCHECK_URL=$(cat /run/secrets/${secretPrefix}/healthcheck_url)
          ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/start" || true
        fi

        ${setupEnvScript}

        # Initialize repo only if it genuinely doesn't exist yet.
        # `restic cat config` exits 10 specifically when the repo is missing; any
        # other non-zero (transient network blip, lock, wrong password) must NOT
        # trigger `init` — doing so aborts the whole run with "config file already
        # exists" under `set -e` and skips the healthcheck success ping.
        set +e
        ${pkgs.restic}/bin/restic -r "$REPO" cat config &>/dev/null
        repo_rc=$?
        set -e
        if [ "$repo_rc" -eq 10 ]; then
          echo "Initializing restic repository..."
          ${pkgs.restic}/bin/restic -r "$REPO" init
        elif [ "$repo_rc" -ne 0 ]; then
          echo "ERROR: cannot reach restic repository (restic exit $repo_rc); aborting without init"
          exit 1
        fi

        ${lib.optionalString hasPostgres ''
          # Dump PostgreSQL databases
          echo "Dumping PostgreSQL databases..."
          mkdir -p /var/backup/postgresql
          for db in ${lib.concatStringsSep " " postgresDatabases}; do
            if ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
              echo "  Dumping $db..."
              ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/pg_dump "$db" > "/var/backup/postgresql/$db.sql"
            else
              echo "  Skipping $db (database not found)"
            fi
          done
        ''}

        # Build list of paths to back up
        PATHS_TO_BACKUP=""

        echo "Checking static backup paths..."
        for path in ${lib.concatMapStringsSep " " yamlEscape staticPaths}; do
          if [ -e "$path" ]; then
            # Resolve symlinks (e.g. systemd's DynamicUser+StateDirectory
            # compat symlink /var/lib/foo -> private/foo) — restic has no
            # follow-symlinks option and backs up an unresolved symlink target
            # as just the symlink itself, silently skipping its contents.
            path=$(${pkgs.coreutils}/bin/readlink -f "$path")
            PATHS_TO_BACKUP="$PATHS_TO_BACKUP $path"
            echo "  Will back up: $path"
          else
            echo "  Skipping (not found): $path"
          fi
        done

        ${lib.optionalString hasPostgres ''
          if [ -e "/var/backup/postgresql" ]; then
            PATHS_TO_BACKUP="$PATHS_TO_BACKUP /var/backup/postgresql"
          fi
        ''}

        ${lib.optionalString hasDockerVolumes ''
          # Discover Docker volumes at runtime (more resilient than hardcoding paths)
          echo "Discovering Docker volumes..."
          for pattern in ${lib.concatMapStringsSep " " yamlEscape dockerVolumePatterns}; do
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
        ''}

        if [ -z "$PATHS_TO_BACKUP" ]; then
          echo "ERROR: No paths to back up!"
          exit 1
        fi

        # Run backup.
        # restic exits 3 when the snapshot was created successfully but some source
        # files could not be read — e.g. ClickHouse (plausible event-data) merges
        # and deletes data parts mid-scan, so files vanish between scan and read.
        # That is a benign race, not a backup failure, so treat exit 3 as success.
        echo "Running restic backup..."
        set +e
        ${pkgs.restic}/bin/restic -r "$REPO" backup \
          --verbose \
          --exclude-caches \
          $TAGS \
          $PATHS_TO_BACKUP
        backup_rc=$?
        set -e
        if [ "$backup_rc" -eq 3 ]; then
          echo "WARNING: some source files could not be read (restic exit 3); snapshot was still created. Continuing."
        elif [ "$backup_rc" -ne 0 ]; then
          echo "ERROR: restic backup failed (exit $backup_rc)"
          exit "$backup_rc"
        fi

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

        echo "=== ${hostName} backup completed at $(date) ==="

        # Notify healthcheck success (if configured)
        if [ -f /run/secrets/${secretPrefix}/healthcheck_url ]; then
          HEALTHCHECK_URL=$(cat /run/secrets/${secretPrefix}/healthcheck_url)
          ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL" || true
        fi
      '';

      # Restore helper script — installed as `backup-restore` on every host
      restoreScript = pkgs.writeShellScriptBin "backup-restore" ''
        set -euo pipefail

        # Everything this tool touches is root-only (/run/secrets/*,
        # /var/restore), so escalate up front rather than failing with a
        # permission error mid-script. /run/wrappers/bin holds the setuid
        # sudo; the plain nix store binary can't elevate.
        if [ "$(id -u)" -ne 0 ]; then
          exec /run/wrappers/bin/sudo "$0" "$@"
        fi

        ${setupEnvScript}

        usage() {
          echo "Backup Restore Tool (${hostName})"
          echo ""
          echo "Usage: backup-restore <command> [options]"
          echo ""
          echo "Commands:"
          echo "  list                    List all snapshots"
          echo "  files <snapshot> [path] List files in a snapshot (optionally filter by path)"
          echo "  restore <snapshot>      Restore a snapshot to /var/restore/<snapshot-id>"
          echo "  restore-db <snapshot>   Restore PostgreSQL databases from a snapshot"
          echo "  verify                  Non-destructively verify the repo and latest snapshot restore"
          echo "  shell                   Open interactive shell with restic configured"
          echo ""
          echo "Examples:"
          echo "  backup-restore list"
          echo "  backup-restore files latest"
          echo "  backup-restore restore latest"
          echo "  backup-restore verify"
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
            ${lib.optionalString (restoreHints != [ ]) ''
              echo ""
              ${lib.concatMapStringsSep "\n" (h: "echo \"${h}\"") restoreHints}
            ''}
            ;;
          restore-db)
            ${
              if hasPostgres then
                ''
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
                ''
              else
                ''
                  echo "No PostgreSQL databases configured on this host."
                ''
            }
            ;;
          verify)
            echo "=== Verifying backup for ${hostName} ==="
            echo ""
            echo "-- Repository integrity check --"
            ${pkgs.restic}/bin/restic -r "$REPO" check
            echo ""

            echo "-- Test restore of latest snapshot --"
            SCRATCH=$(mktemp -d /var/restore/verify-XXXXXX)
            trap 'rm -rf "$SCRATCH"' EXIT
            ${pkgs.restic}/bin/restic -r "$REPO" restore latest --target "$SCRATCH"
            FILE_COUNT=$(find "$SCRATCH" -type f | wc -l)
            echo "Restored $FILE_COUNT file(s) to a scratch directory (will be removed automatically)."
            if [ "$FILE_COUNT" -eq 0 ]; then
              echo "ERROR: latest snapshot restored zero files"
              exit 1
            fi

            ${
              if hasPostgres then
                ''
                  echo ""
                  echo "-- PostgreSQL dump test-load --"
                  for db in ${lib.concatStringsSep " " postgresDatabases}; do
                    dump="$SCRATCH/var/backup/postgresql/$db.sql"
                    if [ -f "$dump" ]; then
                      testdb="verify_''${db}_$$"
                      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/createdb "$testdb"
                      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/psql -q "$testdb" < "$dump"
                      TABLE_COUNT=$(${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/psql -qtA "$testdb" -c "select count(*) from information_schema.tables where table_schema='public'")
                      ${pkgs.sudo}/bin/sudo -u postgres ${pkgs.postgresql_16}/bin/dropdb "$testdb"
                      echo "  $db: dump loads cleanly into a throwaway database ($TABLE_COUNT tables)"
                    else
                      echo "  WARNING: no dump found for $db in latest snapshot"
                    fi
                  done
                ''
              else
                ""
            }

            echo ""
            echo "=== Verification passed ==="
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
      failureScript = pkgs.writeShellScript "restic-backup-failure" ''
        if [ -f /run/secrets/${secretPrefix}/healthcheck_url ]; then
          HEALTHCHECK_URL=$(cat /run/secrets/${secretPrefix}/healthcheck_url)
          ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 "$HEALTHCHECK_URL/fail" || true
        fi
      '';
    in
    {
      # Install restore helper to system PATH
      environment.systemPackages = [ restoreScript ];

      # Ensure backup/restore directories exist
      systemd.tmpfiles.rules = [
        "d /var/restore 0700 root root -"
      ]
      ++ lib.optionals hasPostgres [
        "d /var/backup 0700 root root -"
        "d /var/backup/postgresql 0700 root root -"
      ];

      # Failure notification service
      systemd.services.restic-backup-failure = {
        description = "Notify backup failure";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = failureScript;
        };
      };

      systemd.services.restic-backup = {
        description = "Restic backup for ${hostName}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        onFailure = [ "restic-backup-failure.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = backupScript;
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      systemd.timers.restic-backup = {
        description = "Daily backup timer for ${hostName}";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = onCalendar;
          RandomizedDelaySec = "1h";
          Persistent = true;
        };
      };

      # Pre-upgrade backup service (triggered manually before deployments)
      systemd.services.restic-backup-preupgrade = {
        description = "Pre-upgrade backup for ${hostName}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        onFailure = [ "restic-backup-failure.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${backupScript} --tag pre-upgrade";
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      sops.secrets = lib.genAttrs [
        "${secretPrefix}/server"
        "${secretPrefix}/username"
        "${secretPrefix}/password"
        "${secretPrefix}/restic_password"
        "${secretPrefix}/healthcheck_url"
      ] (_: { });
    };
}
