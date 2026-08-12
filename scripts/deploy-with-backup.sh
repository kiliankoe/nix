#!/usr/bin/env bash
# Deploy NixOS hosts with pre-deployment backups
#
# Usage: ./scripts/deploy-with-backup.sh [hostname]
#
# This script:
# 1. Triggers a pre-upgrade backup on each target host and waits for it
# 2. Deploys the new configuration using deploy-rs
#
# With no hostname given, all NixOS hosts are backed up and deployed.

set -euo pipefail

# Keep in sync with deploy.nodes in flake.nix
ALL_HOSTS=(kepler cubesat)

backup_host() {
  local host="$1"

  echo "=== Pre-deployment backup for $host ==="

  # Start the pre-upgrade backup
  echo "Starting pre-upgrade backup..."
  ssh "$host" "sudo systemctl start restic-backup-preupgrade"

  # Wait for backup to complete and check status
  echo "Waiting for backup to complete..."
  if ssh "$host" "sudo systemctl is-active --quiet restic-backup-preupgrade 2>/dev/null"; then
    # Service is still running, wait for it
    ssh "$host" "journalctl -u restic-backup-preupgrade -f --since 'now'" &
    JOURNAL_PID=$!

    # Wait for service to finish
    while ssh "$host" "sudo systemctl is-active --quiet restic-backup-preupgrade 2>/dev/null"; do
      sleep 2
    done

    kill $JOURNAL_PID 2>/dev/null || true
  fi

  # Check if backup succeeded
  RESULT=$(ssh "$host" "sudo systemctl show restic-backup-preupgrade --property=Result --value")
  if [ "$RESULT" != "success" ]; then
    echo "ERROR: Pre-upgrade backup failed!"
    echo "Check logs: ssh $host 'journalctl -u restic-backup-preupgrade'"
    exit 1
  fi

  echo "Pre-upgrade backup completed successfully."
  echo ""
}

if [ $# -eq 0 ]; then
  HOSTS=("${ALL_HOSTS[@]}")
  TARGET="."
else
  HOSTS=("$1")
  TARGET=".#$1"
fi

for host in "${HOSTS[@]}"; do
  backup_host "$host"
done

echo "=== Deploying to ${HOSTS[*]} ==="
deploy --skip-checks "$TARGET"

echo ""
echo "=== Deployment complete ==="
echo "Pre-upgrade snapshots are tagged with 'pre-upgrade' for easy rollback."
echo "To list snapshots: ssh <host> 'sudo backup-restore list'"
