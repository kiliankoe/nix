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
└── services/         # Docker Compose service definitions
```

## Hosts

- **Voyager**: macOS (aarch64-darwin)
- **Sojourner**: macOS (aarch64-darwin)
- **Kepler**: NixOS (x86_64-linux, headless)
- **Cubesat**: NixOS (x86_64-linux, headless)
- **Midgard**: NixOS (x86_64-linux, desktop)

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

### Secrets in Environment Files

For additional host-specific secrets not managed by sops:

```bash
# ~/.config/secrets/env
export GITHUB_TOKEN="ghp_..."
export DATABASE_URL="postgresql://..."
```

## Docker Services

Some hosts run docker compose services managed through Nix. Each service is defined as a separate module and managed via systemd.
It uses inline compose files to allow for independent compose networks.

### Service Management

```bash
# Start/stop/restart services
sudo systemctl start $servicename
sudo systemctl stop $servicename
sudo systemctl restart $servicename

# Check service status
sudo systemctl status $servicename

# View service logs
journalctl -u $servicename -f
journalctl -u $servicename --since "1 hour ago"

# Enable/disable auto-start
sudo systemctl enable $servicename
sudo systemctl disable $servicename
```

### Service Secrets

Service secrets are managed through **sops-nix** and automatically injected into Docker Compose services.

### Backups

Ensure the `volumesToBackup` attribute is set where applicable. This will automatically backup the listed docker volumes.
