# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

First check what system we are running on using `hostname`. It will likely be one of the known hosts (see @README.md). If building the config for the same host, use `nhb` (an alias for `nh darwin build -H <hostname>`), otherwise use on of the following options.

```bash
# Quick check
statix check .
deadnix
nix flake check --no-build

# For building a nixos host from macOS
ssh nixos@orb 'cd /mnt/mac/Users/kilian/dev/kiliankoe/nix && nixos-rebuild build --flake .#kepler'
```

### Code Formatting

```bash
nixfmt **/*.nix
```

### Coding Style Guidelines

Nix: 2-space indentation, trailing commas in attrsets, one option per line
Filenames and attrs: lowercase, hyphenated where natural (e.g., `paperless.nix`)
Keep modules small and composable; prefer `imports` over large files

## Architecture Overview

This is a unified Nix flake configuration managing multiple systems across macOS and NixOS platforms.

See @README.md for the directory structure and host definitions.

### Key Design Patterns

#### Modular Configuration

Each host imports only the modules it needs. Shared functionality is in `modules/shared/`, platform-specific code is separated into `modules/darwin/` and `modules/nixos/`.

#### Home Manager Integration

User-level configurations are managed through Home Manager:

- Dotfiles (zsh, tmux, git, helix, k9s, zed) in `home/programs/`
- Platform-specific adaptations in `home/darwin.nix` and `home/nixos.nix`
- Per-host customizations (e.g., git email) configured in each host

#### Service Management

Services on kepler use a mix of approaches and live under `hosts/kepler/services/`:

- **Native NixOS services** (examples): freshrss, paperless, uptime-kuma, cockpit
- **Docker services** (examples): changedetection.io, immich, linkding
- Secrets managed through sops-nix integration

#### Secrets Management

- Legacy host-specific secrets stored in `~/.config/secrets/env`
- New secrets managed through `secrets/secrets.yaml` with sops-nix
  - Contains encrypted secrets for services and hosts
  - **Note**: sops-nix populates secrets during activation, not via a systemd service. There is no `sops-nix.service` to depend on - secrets in `/run/secrets/` are available after activation completes.

### Service Development on kepler

When working with Docker services:

```bash
# Service control (on kepler via SSH)
sudo systemctl start $serviceName
sudo systemctl stop $serviceName
sudo systemctl restart $serviceName
sudo systemctl status $serviceName

# View logs
journalctl -u $serviceName -f
journalctl -u $serviceName --since "1 hour ago"
```

To add new services:

- For Docker services: Use the `lib/docker-service.nix` helper, following patterns in `hosts/kepler/services/docker/linkding.nix`
- For native NixOS services: Follow patterns in `hosts/kepler/services/freshrss.nix` or `hosts/kepler/services/paperless.nix`

### Package Management

- `allowUnfree = true` is set globally
- Packages are organized by host in separate `.nix` files
- macOS systems use Homebrew cask for GUI applications via `modules/darwin/homebrew.nix`
