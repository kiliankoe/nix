# Nix Configs

My consolidated Nix configuration for macOS and NixOS systems, including a few services.

```
nix/
├── flake.nix
├── hosts/            # Host-specific configs
├── home/             # Home Manager user configs
├── modules/
│   ├── darwin/       # macOS-specific modules
│   ├── nixos/        # NixOS-specific modules
│   └── shared/       # Cross-platform modules
├── secrets/          # Encrypted secrets (managed by sops-nix)
└── services/         # Server service definitions
```

## Hosts

- **Voyager**: macOS (aarch64-darwin)
- **Cassini**: macOS (aarch64-darwin)
- **Kepler**: NixOS (x86_64-linux, headless)
- **Cubesat**: NixOS (x86_64-linux, headless)

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

**Decrypt to stdout**

```bash
sops -d secrets/secrets.yaml
```

## Services

Services are defined as native NixOS or docker services. Not everything has been migrated to native yet.

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

Kepler uses restic for unified backups of all services (native NixOS + Docker) to an SFTP server. Backups run daily at 4 AM.

### Manual Backup

```bash
# Run backup manually
sudo systemctl start kepler-backup

# Check backup status/logs
journalctl -u kepler-backup -f
```

### Restore

The `kepler-backup-restore` command is available on kepler:

```bash
# List all snapshots
kepler-backup-restore list

# Browse files in a snapshot
kepler-backup-restore files latest
kepler-backup-restore files latest /var/lib/paperless

# Restore everything to /var/restore/<snapshot-id>/
kepler-backup-restore restore latest

# Extract PostgreSQL dumps and show restore commands
kepler-backup-restore restore-db latest

# Open shell with restic configured for manual operations
kepler-backup-restore shell
```

### Restore Workflow

1. `kepler-backup-restore list` - find the snapshot you want
2. `kepler-backup-restore restore <snapshot-id>` - extract to `/var/restore/`
3. Stop the relevant service: `sudo systemctl stop <service>`
4. Copy files from restore dir to original location
5. For PostgreSQL databases: `sudo -u postgres psql <dbname> < /path/to/dump.sql`
6. Start the service: `sudo systemctl start <service>`

### Notifications

Backup failures are reported via healthchecks.io. Configure `kepler_backup/healthcheck_url` in sops secrets to enable.
