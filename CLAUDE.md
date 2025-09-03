# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

To test if the configuration builds correctly, use the following commands. Please do so after any significant config changes to make sure it works.

```bash
# Quick check
nix flake check --no-build

# For macOS
nhb # alias for `nh darwin build -H $currentSystem ~/nix`

# For NixOS
ssh nixos@orb 'cd /mnt/mac/Users/kilian/dev/kiliankoe/nix && nixos-rebuild build --flake .#kepler'
```

See @README.md for a list of hosts. macOS hosts can be built directly like above, NixOS configs are tested locally by running them within `nixos@orb`.

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

Services on kepler use a mix of approaches:

- **Native NixOS services**: changedetection.io, factorio, freshrss, paperless, uptime-kuma
- **Docker services**: Custom applications and services without native NixOS modules
- Secrets managed through sops-nix integration

#### Secrets Management

- Legacy host-specific secrets stored in `~/.config/secrets/env`
- New secrets managed through `secrets/secrets.yaml` with sops-nix
  - Contains encrypted secrets for services and hosts

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

- For Docker services: Use the `lib/docker-service.nix` helper, following patterns in `services/linkding.nix` or `services/forgejo.nix`
- For native NixOS services: Follow patterns in `services/freshrss.nix` or `services/paperless.nix`

### Package Management

- `allowUnfree = true` is set globally
- Packages are organized by host in separate `.nix` files
- macOS systems use Homebrew cask for GUI applications via `modules/darwin/homebrew.nix`
