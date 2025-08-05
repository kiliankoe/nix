# Nix Configs

A consolidated Nix configuration for multiple machines with shared modules and host-specific customizations.

## Architecture

This configuration follows a modular structure that separates shared components from host-specific settings:

```
nix/
├── flake.nix                            # Main flake with all system outputs
├── hosts/                               # Host-specific configurations
│   └── midgard/                         # Desktop workstation (NixOS)
├── iso/                                 # Custom ISO configurations
│   └── mariner-iso.nix                  # Mariner installation ISO
├── modules/                             # Reusable configuration modules
│   ├── darwin/                          # macOS-specific modules
│   │   ├── base.nix
│   │   └── homebrew.nix
│   ├── nixos/                           # NixOS-specific modules
│   │   ├── base.nix                     # Shared NixOS configuration
│   │   ├── forgejo-service.nix          # Forgejo Git hosting service
│   │   ├── mato-service.nix             # Mato webhook service
│   │   └── watchtower-service.nix       # Container auto-updater
│   └── shared/                          # Cross-platform modules
│       ├── base.nix                     # Common modules for all platforms
│       ├── tmux.nix                     # Shared tmux configuration
│       └── zsh.nix                      # Cross-platform zsh setup
```

## Host Profiles

### Voyager (Private Mac)
- **Platform**: macOS (aarch64-darwin)
- **Features**: Full Homebrew integration with extensive cask collection
- **Use Case**: Personal development, creative work, gaming
- **Packages**: Security tools, media software, development utilities

### Sojourner (Work Mac)
- **Platform**: macOS (aarch64-darwin)
- **Features**: Focused on work setup
- **Use Case**: Professional development work
- **Packages**: Work-focused dev tools, containerization, cloud tools

### Mariner (Home Server)
- **Platform**: NixOS (x86_64-linux) - Headless
- **Features**: Headless server configuration, Docker, Tailscale integration, Docker Compose services
- **Use Case**: Home server, self-hosting, automation (SSH access only)
- **Packages**: Minimal server essentials
- **Services**: Forgejo (Git hosting), Mato (personal automation tooling), Watchtower (container updates)

### Midgard (Desktop Workstation)
- **Platform**: NixOS (x86_64-linux) - Desktop
- **Features**: KDE Plasma 6 desktop environment, audio, printing
- **Use Case**: Desktop workstation, development, productivity
- **Packages**: Desktop applications, development tools

## Key Design Principles

1. **Shared Base**: Common tools and configurations are defined once in `modules/shared/`
2. **Platform Isolation**: macOS-specific settings live in `modules/darwin/`
3. **Host Specialization**: Each machine gets tailored package lists and specific configurations
4. **Cross-Platform Compatibility**: Modules handle platform differences automatically (e.g., zsh options)

## Usage

Rebuild any system using the appropriate command for your platform:

```bash
# macOS systems (nix-darwin)
darwin-rebuild build --flake .#voyager
darwin-rebuild build --flake .#sojourner

# Alternative with nh
nh darwin switch -H voyager .
nh darwin switch -H sojourner .

# NixOS systems
nixos-rebuild build --flake .#mariner
nixos-rebuild build --flake .#midgard
sudo nixos-rebuild switch --flake .#mariner
sudo nixos-rebuild switch --flake .#midgard

# Alternative with nh
nh os switch -H mariner .
nh os switch -H midgard .

# Or just build without switching
nh darwin build -H voyager .
nh darwin build -H sojourner .
nh os build -H mariner .
nh os build -H midgard .

# Build custom installation ISO
nix build .#nixosConfigurations.mariner-iso.config.system.build.isoImage
```

## Secrets Management

This configuration supports host-specific secrets through external environment files that are kept outside the git repository.

### Setup

Secrets are loaded automatically through the zsh configuration. Create host-specific environment files:

```bash
mkdir -p ~/.config/secrets/
```

Then create files named after each hostname:
- `~/.config/secrets/voyager-env` - Personal Mac secrets
- `~/.config/secrets/sojourner-env` - Work Mac secrets
- `~/.config/secrets/mariner-env` - Server secrets
- `~/.config/secrets/midgard-env` - Desktop workstation secrets

### Usage

Add your secrets to the appropriate file:

```bash
# ~/.config/secrets/voyager-env
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
export DATABASE_URL="postgresql://..."
```

Secrets are automatically loaded when you open a new shell session and are available as environment variables.

### Security Notes

- Secret files are excluded from git via `.gitignore`
- SSH keys should remain in `~/.ssh/` (not managed by Nix)
- Never commit secrets directly to the repository
- Each host loads only its own secrets file

## Docker Services (Mariner Only)

The Mariner headless server runs several Docker Compose services managed through Nix. Each service is defined as a separate module and managed via systemd. Access the server via SSH for management.

### Current Services

- **Forgejo**: Self-hosted Git service with PostgreSQL database and automated backups
- **Mato**: Custom webhook service for automation
- **Watchtower**: Automatic container updates for labeled containers

### Service Management

Connect via SSH and use standard systemd commands to control services:

```bash
# Start/stop/restart services
sudo systemctl start docker-compose-forgejo
sudo systemctl stop docker-compose-mato
sudo systemctl restart docker-compose-watchtower

# Check service status
sudo systemctl status docker-compose-forgejo

# View service logs
journalctl -u docker-compose-forgejo -f
journalctl -u docker-compose-mato --since "1 hour ago"

# Enable/disable auto-start
sudo systemctl enable docker-compose-watchtower
sudo systemctl disable docker-compose-mato
```

### Service Secrets

Each service that requires secrets expects a corresponding environment file:

```bash
# Required secret files (create as needed)
~/.config/secrets/forgejo.env    # Database credentials, backup settings
~/.config/secrets/mato.env       # Service configuration
# watchtower requires no secrets
```

Example `forgejo.env`:
```bash
POSTGRES_USER=forgejo
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=forgejo
```

### Adding New Docker Services

1. **Create service module**: `modules/nixos/new-service.nix`
2. **Define Docker Compose config**: Embed the compose file using `pkgs.writeText`
3. **Add systemd service**: Configure start/stop/reload commands
4. **Handle secrets**: Create tmpfiles rule for `.env` symlink if needed
5. **Import in host**: Add module to `hosts/mariner/default.nix`

Example service module structure:
```nix
{ config, pkgs, ... }:
let
  composeFile = pkgs.writeText "service-compose.yml" ''
    services:
      app:
        image: your/image:latest
        # ... compose configuration
  '';
in
{
  environment.etc."docker-compose/service/docker-compose.yml".source = composeFile;

  systemd.services.docker-compose-service = {
    description = "Docker Compose service for Service";
    after = [ "docker.service" ];
    requires = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = "/etc/docker-compose/service";
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --force-recreate";
      TimeoutStartSec = 0;
      User = "root";
    };
  };

  # Add secrets symlink if needed
  systemd.tmpfiles.rules = [
    "d /etc/docker-compose/service 0755 root root -"
    "L+ /etc/docker-compose/service/.env - - - - /home/kilian/.config/secrets/service.env"
  ];
}
```

## Custom Installation ISO

This configuration includes a custom NixOS installation ISO for Mariner that contains your complete system configuration pre-installed.

### Building the ISO

```bash
# Build custom Mariner installation ISO (large download, takes time)
nix build .#nixosConfigurations.mariner-iso.config.system.build.isoImage

# ISO will be available at:
# ./result/iso/nixos-*.iso
```

### What's Included

The custom ISO contains:
- **Complete Mariner configuration** - All packages, services, and settings
- **Docker Compose services** - Forgejo, Mato, Watchtower (ready to activate)
- **Development tools** - Your entire development environment
- **SSH access** - Pre-configured for remote installation (user: kilian, password: nixos)
- **Installation tools** - Standard NixOS installer plus your preferred tools

### Installation Process

1. **Boot from the custom ISO** - Your system environment is already available
2. **Partition and format drives** - Use standard NixOS installation tools (parted, cryptsetup, etc.)
3. **Generate hardware configuration**:
   ```bash
   nixos-generate-config --root /mnt
   ```
4. **Copy your flake configuration**:
   ```bash
   # Clone your repo or copy configuration
   git clone <your-repo> /mnt/etc/nixos
   ```
5. **Install with your configuration**:
   ```bash
   nixos-install --flake /mnt/etc/nixos#mariner
   ```
6. **Reboot and activate services**:
   ```bash
   # After reboot, start your Docker services
   sudo systemctl start docker-compose-forgejo
   sudo systemctl start docker-compose-mato
   sudo systemctl start docker-compose-watchtower
   ```

### Benefits

- **Pre-configured environment** - Skip post-installation setup
- **Reproducible deployments** - Same configuration every time
- **Remote installation** - SSH into the live environment
- **All dependencies included** - No need to download packages during installation

**Note**: The ISO will be several GB in size as it includes all your packages and Docker images.

## Adding New Hosts

1. Create a new directory in `hosts/` with a `default.nix`
2. Import appropriate modules from `modules/`
3. Create host-specific packages in `packages/` if needed
4. Add the configuration to `flake.nix` outputs
5. Optionally create `~/.config/secrets/<hostname>-env` for host-specific secrets
