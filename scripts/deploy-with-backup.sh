#!/usr/bin/env bash
# Deploy a NixOS host with pre-deployment backup
#
# Usage: ./scripts/deploy-with-backup.sh <hostname>
#
# This script:
# 1. Triggers a pre-upgrade backup on the target host
# 2. Waits for the backup to complete
# 3. Deploys the new configuration using deploy-rs

set -euo pipefail

HOST="${1:-}"

if [ -z "$HOST" ]; then
  echo "Usage: $0 <hostname>"
  echo "Example: $0 cubesat"
  exit 1
fi

echo "=== Pre-deployment backup for $HOST ==="

# Start the pre-upgrade backup
echo "Starting pre-upgrade backup..."
ssh "$HOST" "sudo systemctl start ${HOST}-backup-preupgrade"

# Wait for backup to complete and check status
echo "Waiting for backup to complete..."
if ssh "$HOST" "sudo systemctl is-active --quiet ${HOST}-backup-preupgrade 2>/dev/null"; then
  # Service is still running, wait for it
  ssh "$HOST" "journalctl -u ${HOST}-backup-preupgrade -f --since 'now'" &
  JOURNAL_PID=$!

  # Wait for service to finish
  while ssh "$HOST" "sudo systemctl is-active --quiet ${HOST}-backup-preupgrade 2>/dev/null"; do
    sleep 2
  done

  kill $JOURNAL_PID 2>/dev/null || true
fi

# Check if backup succeeded
RESULT=$(ssh "$HOST" "sudo systemctl show ${HOST}-backup-preupgrade --property=Result --value")
if [ "$RESULT" != "success" ]; then
  echo "ERROR: Pre-upgrade backup failed!"
  echo "Check logs: ssh $HOST 'journalctl -u ${HOST}-backup-preupgrade'"
  exit 1
fi

echo "Pre-upgrade backup completed successfully."
echo ""

# Deploy using deploy-rs
echo "=== Deploying to $HOST ==="
nix run github:serokell/deploy-rs -- ".#$HOST"

echo ""
echo "=== Deployment complete ==="
echo "Pre-upgrade snapshot is tagged with 'pre-upgrade' for easy rollback."
echo "To list snapshots: ssh $HOST 'sudo ${HOST}-backup-restore list'"
