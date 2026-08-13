# Unified restic backup for all kepler services (native NixOS + Docker)
# Backs up to SFTP server using credentials from sops secrets
#
# Notifications: Uses healthchecks.io (or compatible) for dead man's switch alerts.
# Set kepler_backup/healthcheck_url in sops to enable notifications.
#
# Restore: Use `backup-restore` command (installed to system PATH)
{
  config,
  pkgs,
  lib,
  ...
}:

let
  resticBackup = import ../../../lib/restic-backup.nix { inherit pkgs lib; };
in
resticBackup.mkResticBackupService {
  hostName = "kepler";
  onCalendar = "04:00";

  staticPaths = [
    "/var/lib/hister"
    "/var/lib/mediawiki-personal"
    "/var/lib/mediawiki-family"
    "/var/lib/paperless"
  ]
  ++ config.k.backup.paths;

  # Docker volume name patterns collected from service modules, matched
  # against `docker volume ls --filter "name=..."`.
  dockerVolumePatterns = lib.unique config.k.backup.dockerVolumes;

  postgresDatabases = [
    "freshrss"
  ];

  restoreHints = [
    "To restore specific services, copy files to their original locations:"
    "  - Paperless: cp -r $RESTORE_DIR/var/lib/paperless/* /var/lib/paperless/"
    "  - Docker volumes: cp -r $RESTORE_DIR/var/lib/docker/volumes/* /var/lib/docker/volumes/"
    ""
    "For PostgreSQL databases, use: backup-restore restore-db <snapshot>"
  ];
}
