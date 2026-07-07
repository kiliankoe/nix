# Nix Configs

My consolidated Nix configuration for macOS and NixOS systems, including a few services.

## Hosts

- Voyager: macOS (aarch64-darwin)
- Cassini: macOS (aarch64-darwin)
- Kepler: NixOS (x86_64-linux, headless)
- Cubesat: NixOS (x86_64-linux, headless)

## Usage

```bash
# macOS systems (nix-darwin)
darwin-rebuild build --flake .#voyager
darwin-rebuild switch --flake .#voyager
# Alternative with nh
nh darwin build -H voyager .
nh darwin switch -H voyager .

# NixOS systems
nixos-rebuild build --flake .#kepler
sudo nixos-rebuild switch --flake .#kepler
# Alternative with nh
nh os build -H kepler .
nh os switch -H kepler .
```

## Secrets

Secrets are stored encrypted in `secrets/secrets.yaml` and automatically decrypted using sops-nix.

### Setup

Key is stored in `~/.config/sops/age.key`, make sure that exists.

### Managing Secrets

**Edit secrets**

```bash
sops secrets/secrets.yaml
```

## Services

Services are defined as native NixOS or docker services. Not everything has been migrated to native yet.
Kepler service definitions live under `hosts/kepler/services/` (Docker services in `hosts/kepler/services/docker/`).

### Service Management

```bash
sudo systemctl status $servicename
sudo systemctl start $servicename
sudo systemctl stop $servicename
sudo systemctl restart $servicename

journalctl -u $servicename -f
journalctl -u $servicename --since "1 hour ago"
```

#### Docker Service Logs

Docker-based services run in detached mode `docker-compose up -d`, so their container logs are not captured by journalctl.

```bash
cd /etc/docker-compose/$servicename
sudo docker-compose logs -f
# or
sudo docker-compose logs --tail=50
```

This is intentional to keep container logs separate and avoid interleaving multiple container outputs in journald.

## Backups

Both kepler and cubesat use restic for backups to an SFTP server, driven by
the same shared tooling (`lib/restic-backup.nix`) so both hosts are operated
identically — same systemd unit names, same restore CLI.

```bash
# Run backup manually
sudo systemctl start restic-backup

# Run pre-upgrade backup (tagged for easy identification/rollback)
sudo systemctl start restic-backup-preupgrade

# Check backup status/logs
journalctl -u restic-backup -f
```

The `backup-restore` command is available on both hosts:

```bash
backup-restore list                      # List all snapshots
backup-restore files latest              # Browse files in a snapshot
backup-restore restore latest            # Restore to /var/restore/
backup-restore restore-db latest         # Extract PostgreSQL dumps (kepler only)
backup-restore verify                    # Non-destructively verify repo integrity + restorability
backup-restore shell                     # Interactive restic shell
```

- **Kepler** backs up all services (native NixOS + Docker) daily at 4 AM.
- **Cubesat** backs up pangolin data (`/var/lib/pangolin`) and uptime-kuma daily at 3 AM.

#### Deploy with Backup

Use the deploy script to automatically create a pre-upgrade backup before deploying:

```bash
./scripts/deploy-with-backup.sh cubesat
```

This creates a tagged snapshot that can be used for rollback if needed.

### Verifying Backups Work

`backup-restore verify` runs a full round-trip check without touching any
live data: it runs `restic check` against the repo, restores the latest
snapshot into a throwaway scratch directory (deleted automatically
afterward), and — on kepler — loads each PostgreSQL dump into a throwaway
database that's dropped immediately after a sanity check. Run it any time you
want confidence backups are actually restorable, on either host, the same way.

### Restore Workflow

1. `backup-restore list` - find the snapshot you want
2. `backup-restore restore <snapshot-id>` - extract to `/var/restore/`
3. Stop the relevant service: `sudo systemctl stop <service>`
4. Copy files from restore dir to original location
5. For PostgreSQL databases (kepler only): `sudo -u postgres psql <dbname> < /path/to/dump.sql`
6. Start the service: `sudo systemctl start <service>`

### Notifications

Backup failures are reported via healthchecks.io. Configure `<host>_backup/healthcheck_url` in sops secrets to enable.
