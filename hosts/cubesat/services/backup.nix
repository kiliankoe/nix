# Restic backup for cubesat (pangolin service)
# Backs up to SFTP server using credentials from sops secrets
#
# Notifications: Uses healthchecks.io (or compatible) for dead man's switch alerts.
# Set cubesat_backup/healthcheck_url in sops to enable notifications.
#
# Restore: Use `backup-restore` command (installed to system PATH)
#
# Pre-upgrade backups: Run `systemctl start restic-backup-preupgrade` before deployments
{ pkgs, lib, ... }:

let
  resticBackup = import ../../../lib/restic-backup.nix { inherit pkgs lib; };
in
resticBackup.mkResticBackupService {
  hostName = "cubesat";
  onCalendar = "03:00";

  staticPaths = [
    "/var/lib/pangolin/config"
    "/var/lib/uptime-kuma"
  ];

  restoreHints = [
    "To restore pangolin data:"
    "  1. Stop the service: sudo systemctl stop pangolin"
    "  2. Copy files: cp -r $RESTORE_DIR/var/lib/pangolin/* /var/lib/pangolin/"
    "  3. Start the service: sudo systemctl start pangolin"
  ];
}
