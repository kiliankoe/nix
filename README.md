# Nix Configs

A consolidated Nix configuration for multiple machines with shared modules and host-specific customizations.

## Architecture

This configuration follows a modular structure that separates shared components from host-specific settings:

```
nix/
├── flake.nix                    # Main flake with all system outputs
├── hosts/                       # Host-specific configurations
│   ├── voyager/                 # Private Mac (macOS + Homebrew)
│   ├── sojourner/               # Work Mac (macOS, minimal)
│   └── mariner/                 # Home server (NixOS)
├── modules/                     # Reusable configuration modules
│   ├── darwin/                  # macOS-specific modules
│   │   ├── base.nix             # Common macOS settings
│   │   └── homebrew.nix         # Homebrew configuration
│   └── shared/                  # Cross-platform modules
│       ├── dev-tools.nix        # Common development tools
│       ├── tmux.nix             # Shared tmux configuration
│       └── zsh.nix              # Cross-platform zsh setup
└── packages/                    # Host-specific package lists
    ├── voyager-packages.nix     # Personal tools & security packages
    ├── sojourner-packages.nix   # Work-focused packages
    └── mariner-packages.nix     # Server packages
```

## Host Profiles

### Voyager (Private Mac)
- **Platform**: macOS (aarch64-darwin)
- **Features**: Full Homebrew integration with extensive cask collection
- **Use Case**: Personal development, creative work, gaming
- **Packages**: Security tools, media software, development utilities

### Sojourner (Work Mac)
- **Platform**: macOS (aarch64-darwin)
- **Features**: Minimal configuration, no Homebrew
- **Use Case**: Professional development work
- **Packages**: Work-focused dev tools, containerization, cloud tools

### Mariner (Home Server)
- **Platform**: NixOS (x86_64-linux)
- **Features**: Server optimizations, Docker, Tailscale integration
- **Use Case**: Home server, self-hosting, automation
- **Packages**: Minimal server essentials

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
sudo nixos-rebuild switch --flake .#mariner

# Alternative with nh
nh os switch -H mariner .
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

## Adding New Hosts

1. Create a new directory in `hosts/` with a `default.nix`
2. Import appropriate modules from `modules/`
3. Create host-specific packages in `packages/` if needed
4. Add the configuration to `flake.nix` outputs
5. Optionally create `~/.config/secrets/<hostname>-env` for host-specific secrets
