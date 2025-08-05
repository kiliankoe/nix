# Nix Configs

My consolidated Nix configuration for macOS and NixOS systems, including custom Docker services.

```
nix/
├── flake.nix
├── hosts/            # Host-specific configurations
├── iso/              # Custom NixOS installation ISO
├── modules/
│   ├── darwin/       # macOS-specific modules
│   ├── nixos/        # NixOS-specific modules
│   └── shared/       # Cross-platform modules
└── services/         # Docker Compose service definitions
```

## Hosts

### Voyager (Private Mac)
- **Platform**: macOS (aarch64-darwin)

### Sojourner (Work Mac)
- **Platform**: macOS (aarch64-darwin)

### Mariner (Home Server)
- **Platform**: NixOS (x86_64-linux) - Headless

### Midgard (Desktop Workstation)
- **Platform**: NixOS (x86_64-linux) - Desktop

## Usage

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

## Secrets

This configuration supports host-specific secrets through external environment files that are kept outside the git repository.

### Setup

Secrets are loaded automatically through the zsh configuration. Create host-specific environment files:

```bash
mkdir -p ~/.config/secrets/
touch ~/.config/secrets/env
```

### Usage

Add your secrets to the appropriate file:

```bash
# ~/.config/secrets/env
export OPENAI_API_KEY="sk-..."
export GITHUB_TOKEN="ghp_..."
export DATABASE_URL="postgresql://..."
```

## Docker Services

Mariner runs several Docker Compose services managed through Nix. Each service is defined as a separate module and managed via systemd.
It uses inline compose files to allow for independent compose networks.

See `services/` for service definitions.

### Service Management

Connect via SSH and use standard systemd commands to control services:

```bash
# Start/stop/restart services
sudo systemctl start docker-compose-$serviceName
sudo systemctl stop docker-compose-$serviceName
sudo systemctl restart docker-compose-$serviceName

# Check service status
sudo systemctl status docker-compose-$serviceName

# View service logs
journalctl -u docker-compose-$serviceName -f
journalctl -u docker-compose-$serviceName --since "1 hour ago"

# Enable/disable auto-start
sudo systemctl enable docker-compose-$serviceName
sudo systemctl disable docker-compose-$serviceName
```

### Service Secrets

Each service that requires secrets (db credentials, backup settings, etc.) expects a corresponding environment file:

```bash
~/.config/secrets/$serviceName.env
```

### Adding New Docker Services

1. **Create service module**: `services/new-service.nix`
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

This configuration includes a custom NixOS installation ISO for Mariner with the complete system environment pre-configured.

### Building the ISO

```bash
nix build .#nixosConfigurations.mariner-iso.config.system.build.isoImage

# ISO will be available at:
# ./result/iso/nixos-*.iso
```

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
   sudo systemctl start docker-compose-$serviceName
   ```
