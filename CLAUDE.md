# nix

> **This is a living document.** Keep it updated as the project evolves: document new features, record _why_ decisions were made (not just what), and remove or revise anything that becomes outdated. The goal is that anyone (or any AI) can read this file cold and fully understand the project's current state, architecture, and the reasoning behind it.

This is a unified Nix flake configuration managing multiple systems across macOS and NixOS platforms.

See @README.md for the directory structure and host definitions.

## Build Commands

First check what system we are running on using `hostname`. It will likely be one of the known hosts (see @README.md).
If building the config for the same host, use `nh darwin build -H <hostname>`.

Never switch to a new config and leave that to the user.

## Formatting and Style

Nix: 2-space indentation, trailing commas in attrsets, one option per line
Filenames and attrs: lowercase, hyphenated where natural (e.g., `paperless.nix`)
Keep modules small and composable; prefer `imports` over large files

Always run the following commands after making changes and fix any issues they report.

```bash
nixfmt **/*.nix
statix check .
deadnix --fail
nix flake check --no-build
```

## Deployment

All hosts are reachable directly by their hostname (e.g. `ssh kepler`) over Tailscale — no IP addresses or `.local` suffixes needed.

- **macOS hosts**: `darwin-rebuild switch --flake .#<host>`
- **NixOS hosts**: `deploy-rs` is configured for remote deployment to kepler and cubesat
- **Deploy with backup**: `./scripts/deploy-with-backup.sh <host>` creates a tagged restic snapshot before deploying

### CI

GitHub Actions (`.github/workflows/`):

- `check.yml`: flake check, statix lint, nixfmt format check, deadnix — on push to main and PRs
- `ci.yml`: evaluates all darwin and nixos configurations — on push to main and PRs

Dependency updates are handled by the hosted [Mend Renovate](https://github.com/apps/renovate) GitHub App (see [Docker Image Updates](#docker-image-updates) below) — no in-repo workflow.

## Architecture Overview

### Key Design Patterns

#### Modular Configuration

Each host imports only the modules it needs. Shared functionality is in `modules/shared/`, platform-specific code is separated into `modules/darwin/` and `modules/nixos/`.

#### Central Port Registry & Service Registration (`modules/shared/k.nix`)

`k.nix` defines the `k` option namespace with three purposes:

1. **Port registry** (`k.ports`): all service ports in one place (8380–8402 range + plex at 32400) to prevent conflicts
2. **Monitoring registration** (`k.monitoring`): services self-register their HTTP endpoints, Docker containers, and systemd units for Prometheus monitoring
3. **Backup registration** (`k.backup`): services declare Docker volume patterns to include in backups

Services reference ports via `config.k.ports.<name>` rather than hardcoding values to prevent accidental collisions.

#### Home Manager Integration

User-level configurations are managed through Home Manager:

- Programs (zsh, tmux, git, helix, k9s, zed, starship, direnv, zoxide, sops-env) in `home/programs/`
- Platform-specific adaptations in `home/darwin.nix` and `home/nixos.nix`
- Per-host customizations (e.g., git email) configured in each host

#### Service Management

Services on kepler live under `hosts/kepler/services/`:

- **Native NixOS services**: freshrss, paperless, uptime-kuma
- **Docker services**: actual, changedetection, immich, jobfinder, lehmuese, linkding, mato, newsdiff, pinchflat, plausible, rustypaste, swiftdebot, watchtower, wbbash
- **Monitoring stack** (`services/monitoring/`): Prometheus, Grafana, AlertManager, exporters (node, PostgreSQL, Redis, systemd, blackbox), cAdvisor
- Secrets managed through sops-nix integration

Services on cubesat live under `hosts/cubesat/services/`:

- **Pangolin**: API server with GeoIP, email, CORS configuration

#### Docker Service Helper (`lib/docker-service.nix`)

`mkDockerComposeService` standardizes Docker Compose services. Key features:

- Generates `compose.yml` and `.env` files in `/etc/docker-compose/<name>/`
- `environment`: per-container env vars; use `{ secret = "sops_key"; }` for secrets (auto-declares `sops.secrets`)
- `monitoring`: auto-registers containers, systemd units, and optional HTTP endpoints in `k.monitoring`
- `backupVolumes`: registers Docker volume patterns in `k.backup`
- `auto_update`: when `true`, adds watchtower labels to all containers; when `false`, the image should be Renovate-pinned (see Docker Image Updates)
- Sets `restartTriggers` on the systemd unit, so a deploy that changes the compose file or env scripts restarts the service and actually applies the change (an image bump without this only rewrites the file on disk)

Follow patterns in `hosts/kepler/services/docker/linkding.nix` when adding new Docker services.

#### Docker Image Updates

Two mechanisms keep Docker images current; each service uses exactly one.

- **watchtower** (`auto_update = true`): watchtower auto-pulls new images for labelled containers. Used for first-party `kiliankoe/*` images (swiftdebot, newsdiff, lehmuese, wbbash, mato, jobfinder). watchtower's own service must stay `auto_update = false` — if it updates its own container it can cancel an in-flight update batch and leave other containers stopped.
- **Renovate** (`auto_update = false` + pinned image): third-party images are pinned to `repo:tag@sha256:digest` and bumped via PRs. Renovate-managed services: changedetection, pinchflat, actual, rustypaste, immich, plausible, watchtower.

To place an image under Renovate: set `auto_update = false`, pin the image to `repo:tag@sha256:digest`, and add a `# renovate` comment line directly above the `image =` line. `renovate.json` (repo root) has a customManager that only matches `image =` lines carrying that marker, so it is opt-in per image. Renovate itself runs as the hosted [Mend Renovate](https://github.com/apps/renovate) GitHub App, event-driven on the App's own schedule — there is no in-repo workflow or App secret to maintain. Database images (postgres, clickhouse, valkey) are pinned to a major line — Renovate will not auto-propose major bumps.

#### NAS Mounts on kepler (`hosts/kepler/systemd.nix`)

kepler mounts CIFS shares from the Synology NAS (`marvin`, reached over Tailscale) for media and photos. These are the project's historically flakiest piece, so the wiring is centralized in `mkCifsMount`, which builds three things per share: the mount unit, a 5-minute health watchdog that remounts a stale/dropped share, and the dependency edges to every consuming service.

**Adding a service that reads or writes a NAS path: just add its systemd unit name to the mount's `consumers` list** (`mediaMount` for `/mnt/media`, `immichMount` for `/mnt/photos/immich`). Do not hand-write `after`/`bindsTo`/`wants` on the service — `mkCifsMount` derives all of it from that one list. For Docker services the unit name is the `serviceName` passed to `mkDockerComposeService`; the generated `after`/`bindsTo` merge with the helper's `after = docker.service`.

The reasoning the list encodes, so it isn't re-broken:

- **consumer → mount** (`after` + `bindsTo`): the service is ordered after the mount and stopped if the mount drops, so nothing ever writes into an unmounted directory. This matters most for Docker bind mounts — a container started before the share is mounted captures the empty local dir and stays blind to the share even after it mounts (downloads silently land on the system disk).
- **mount → consumer** (`upholds`): while the mount is active systemd keeps the consumers started, so the watchdog remounting a dropped share auto-restarts them. `bindsTo` only propagates _stop_, not _start_ — without `upholds`, a transient NAS/Tailscale blip left consumers dead until the next switch (and a switch could need running twice).
- **Tailscale reachability gate**: the mount's `ExecStart` pings `nasHost` (up to 60s) before `mount.cifs`. `After=tailscaled.service` only orders after the daemon _starts_, not after the tunnel reconverges, so a Tailscale package bump in the same switch otherwise races the mount and fails the first attempt.

A single `consumers` list is the source of truth — there is intentionally no second list to keep in sync. If you find yourself adding mount ordering anywhere outside `mkCifsMount`, that's the smell that caused the original drift (a service writing to `/mnt/media` with no mount dependency at all).

#### Secrets Management

- Legacy host-specific secrets stored in `~/.config/secrets/env`
- New secrets managed through `secrets/secrets.yaml` with sops-nix
  - Contains encrypted secrets for services and hosts
  - **Note**: sops-nix populates secrets during activation, not via a systemd service. There is no `sops-nix.service` to depend on - secrets in `/run/secrets/` are available after activation completes.

#### Monitoring

Prometheus + Grafana + AlertManager stack in `hosts/kepler/services/monitoring/`:

- **Prometheus**: scrapes all registered targets (from `k.monitoring`), 30-day retention
- **Grafana**: pre-provisioned dashboards, Prometheus data source
- **AlertManager**: email notifications for service failures
- **Exporters**: node, PostgreSQL, Redis, systemd, blackbox (HTTP probing)
- **cAdvisor**: Docker container resource metrics

When registering a service's `httpEndpoints` in `k.monitoring`, use `0.0.0.0` or `127.0.0.1` in the probe URL — never `localhost`. The blackbox exporter's `http` prober prefers IPv6, so `localhost` resolves to `::1`; since nginx and the native services only listen on IPv4, the blackbox connection is refused and the `EndpointDown` alert fires for a service that is actually healthy. `ip_protocol_fallback` only covers DNS resolution, not a failed connection, so it does not rescue this case.

#### Backups

See @README.md for full backup and restore documentation.

- **Kepler**: daily restic backup at 4 AM — native services, Docker volumes (from `k.backup`), PostgreSQL dumps. Restore tool: `kepler-backup-restore`
- **Cubesat**: daily restic backup at 3 AM — Pangolin data. Restore tool: `cubesat-backup-restore`
- Both use SFTP backend, healthchecks.io failure notifications, 7 daily / 4 weekly / 6 monthly retention

### Service Development on kepler

```bash
# Service control (on kepler via SSH)
sudo systemctl start $serviceName
sudo systemctl stop $serviceName
sudo systemctl restart $serviceName
sudo systemctl status $serviceName

# View logs (systemd)
journalctl -u $serviceName -f
journalctl -u $serviceName --since "1 hour ago"

# View logs (Docker container)
cd /etc/docker-compose/$serviceName
sudo docker-compose logs -f
```

To add new services:

- For Docker services: Use `lib/docker-service.nix` helper, following patterns in `hosts/kepler/services/docker/linkding.nix`
- For native NixOS services: Follow patterns in `hosts/kepler/services/freshrss.nix` or `hosts/kepler/services/paperless.nix`
- If the service touches a NAS path (`/mnt/media`, `/mnt/photos/immich`): add its unit name to the relevant `consumers` list in `hosts/kepler/systemd.nix` — see [NAS Mounts on kepler](#nas-mounts-on-kepler-hostskeplersystemdnix). Don't hand-wire mount ordering.

### Package Management

- `allowUnfree = true` is set globally
- Packages are organized by host in separate `.nix` files
- macOS systems use Homebrew cask for GUI applications via `modules/darwin/homebrew.nix` and host specific installations via `hosts/<hostname>/homebrew.nix`.
