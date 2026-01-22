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

Both kepler and cubesat use restic for backups to an SFTP server.

### Kepler

Kepler backs up all services (native NixOS + Docker) daily at 4 AM.

```bash
# Run backup manually
sudo systemctl start kepler-backup

# Check backup status/logs
journalctl -u kepler-backup -f
```

The `kepler-backup-restore` command is available on kepler:

```bash
kepler-backup-restore list                      # List all snapshots
kepler-backup-restore files latest              # Browse files in a snapshot
kepler-backup-restore restore latest            # Restore to /var/restore/
kepler-backup-restore restore-db latest         # Extract PostgreSQL dumps
kepler-backup-restore shell                     # Interactive restic shell
```

### Cubesat

Cubesat backs up pangolin data (`/var/lib/pangolin`) daily at 3 AM.

```bash
# Run backup manually
sudo systemctl start cubesat-backup

# Run pre-upgrade backup (tagged for easy identification)
sudo systemctl start cubesat-backup-preupgrade

# Check backup status/logs
journalctl -u cubesat-backup -f
```

The `cubesat-backup-restore` command is available on cubesat:

```bash
cubesat-backup-restore list                     # List all snapshots
cubesat-backup-restore files latest             # Browse files in a snapshot
cubesat-backup-restore restore latest           # Restore to /var/restore/
cubesat-backup-restore shell                    # Interactive restic shell
```

#### Deploy with Backup

Use the deploy script to automatically create a pre-upgrade backup before deploying:

```bash
./scripts/deploy-with-backup.sh cubesat
```

This creates a tagged snapshot that can be used for rollback if needed.

### Restore Workflow

1. `<host>-backup-restore list` - find the snapshot you want
2. `<host>-backup-restore restore <snapshot-id>` - extract to `/var/restore/`
3. Stop the relevant service: `sudo systemctl stop <service>`
4. Copy files from restore dir to original location
5. For PostgreSQL databases (kepler only): `sudo -u postgres psql <dbname> < /path/to/dump.sql`
6. Start the service: `sudo systemctl start <service>`

### Notifications

Backup failures are reported via healthchecks.io. Configure `<host>_backup/healthcheck_url` in sops secrets to enable.
