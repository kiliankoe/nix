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
- **Sojourner**: macOS (aarch64-darwin)
- **Kepler**: NixOS (x86_64-linux, headless)
- **Cubesat**: NixOS (x86_64-linux, headless)
- **Gaia**: NixOS (x86_64-linux, desktop)

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

# Enable/disable auto-start
sudo systemctl enable $servicename
sudo systemctl disable $servicename
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
