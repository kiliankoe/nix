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

All hosts are reachable directly by their hostname (e.g. `ssh kepler`) over Tailscale — no IP addresses or `.local` suffixes needed. mosh is also available everywhere (`mosh kepler`); its UDP range is opened on `tailscale0` only, since cubesat is WAN-exposed.

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

- Programs (zsh, tmux, git, ghostty, helix, k9s, lazygit, zed, starship, direnv, zoxide, sops-env, claude, eilmeldung) in `home/programs/`
- `claude.nix` writes the account-independent Claude Code config (CLAUDE.md, commands, skills) from one source into every config dir the host has, so the two accounts can't drift. `settings.json` is the one out-of-store entry: Claude Code rewrites it itself, so it's an `mkOutOfStoreSymlink` at `dotfiles/claude/settings.json` and in-session changes land directly in git. This works because Claude Code passes `allowSymlink: true` for *user* settings specifically (project/local settings get `false` and refuse to write through a link) — if an upgrade changes that, writes fail loudly with "Refusing to write through symlink" and it has to revert to a copy. Details worth not re-deriving:
  - `~/.claude` is always the host's _primary_ account, never an unused placeholder. Shell aliases only exist in interactive zsh, so a bare `claude` from a script, editor extension, or launchd job has to land somewhere logged in. It's also a special case in Claude Code itself: the default dir keeps its state in `~/.claude.json` and its credentials under the bare `Claude Code-credentials` keychain entry, while every other dir gets `<dir>/.claude.json` and a keychain entry suffixed with a hash of its path. Renaming it therefore costs a re-login.
  - Hosts whose primary account isn't the personal one set `k.claude.personalConfigDir` (only cassini, the work machine). Everywhere else the personal account _is_ `~/.claude` and `pcl` passes through to plain `claude`, so `pcl` means "the personal account" on every host and can never open an unauthenticated dir.
  - `--manual` is a zsh global alias, so it composes with either entry point (`claude --manual`, `pcl --manual`) rather than needing a variant of each. It denies the edit tools via `--settings` and appends `claude/manual-mode.md` to the system prompt, for sessions where every change should be shown rather than applied.
  - `claude/command-guard.jq` is a `PreToolUse` hook for Bash calls, registered in `settings.json` and installed by `claude.nix` as `claude-command-guard`. It exists because permission rules match a literal command prefix: `Bash(rm -rf:*)` catches `rm -rf` and misses `rm -fr`, `rm -r -f`, and `sudo rm -rf`. The hook parses the command into tokens instead, splits on shell operators so a command behind `&&` is judged on its own, and recurses into carriers (`ssh host …`, `sh -c …`) that take a command as an argument. Details worth not re-deriving:
    - It answers `ask`, never `deny`. A false positive costs one keystroke; a false deny costs a wedged session and a config edit. Nothing is given up by that — Claude Code evaluates the `deny` rules in `settings.json` regardless of what a hook returns, so those stay the hard backstop underneath.
    - `command-guard-tests.txt` runs in the derivation's check phase, so a rule that stops matching fails the build instead of silently no longer prompting. The `pass` half of the suite is the load-bearing half: a guard that prompts on ordinary work gets clicked through on reflex.
    - `settings.json` names the hook by absolute path (`/etc/profiles/per-user/kilian/bin/…`) rather than relying on PATH, because Claude Code launched outside an interactive shell (editor extension, launchd) may not have the profile on PATH. That path is stable across generations because `mksystem.nix` sets `useUserPackages`. It also means the guard has to be installed on every host that gets `settings.json` — a missing hook binary exits 127, which Claude Code treats as a non-blocking error, so it would fail open silently.
    - Wrappers that take positional arguments of their own (`timeout`, `xargs`, `nice`) are deliberately not unwrapped; skipping their operands correctly needs a real parser, and guessing wrong reads the operand as the command. Those fall through to the `settings.json` rules.
    - The off-the-shelf option here is [destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard), which does the same job far more thoroughly. It packages fine under nix (checked: builds against nixpkgs' stable rustc despite the nightly pin in `rust-toolchain.toml`), but it's heavy and new, our own solution is fine for now.
    - Platform-specific adaptations in `home/darwin.nix` and `home/nixos.nix`
- `eilmeldung.nix` is the TUI RSS reader, imported from `home/darwin.nix` so it lands on both macOS hosts. It syncs against freshrss on kepler over the Google Reader API (`https://rss.kilko.de/api/greader.php/`), which is why the whole read/starred state lives on the server and this config is disposable. Details worth not re-deriving:
  - It is not in nixpkgs. Upstream ships its own flake, so the input provides both the package and the home-manager module (`inputs.eilmeldung.homeManager.default`, note the attr is `homeManager`, not `homeManagerModules`). The module's `package` default is `pkgs.eilmeldung`, which only exists via upstream's overlay; setting `package` from `inputs.eilmeldung.packages.<system>.default` gets the same derivation without applying an overlay globally.
  - The freshrss credential is the *API password* from the freshrss profile, a separate value from the account password, and API access has to be enabled in freshrss's authentication settings. It lives in sops as `freshrss/api_password`.
  - Secrets marked `cmd:` are run through `Command::new`, not a shell, so `SOPS_AGE_KEY_FILE=… sops …` would be read as a binary name. Hence the `writeShellScript` wrapper that exports the variable and then execs sops. The generated config only ever contains that store path, never the password.
  - Alternatives evaluated: newsboat syncs correctly too and is in nixpkgs, but with `urls-source "freshrss"` the home-manager module's structured `urls`/`queries` options go unused and everything ends up in `extraConfig`. nom was rejected outright: its freshrss "backend" only calls `ClientLogin` and `subscription/list` to import the feed list, then fetches feeds from the origin and keeps read/starred state in local SQLite, so nothing syncs back.
- Per-host customizations (e.g., git email) configured in each host

#### Service Management

Services on kepler live under `hosts/kepler/services/`:

- **Native NixOS services**: freshrss, paperless, uptime-kuma
- **Docker services**: actual, changedetection, immich, jobfinder, lehmuese, linkding, mato, newsdiff, openclaw, pinchflat, plausible, rustypaste, swiftdebot, watchtower, wbbash, yamtrack
- **Monitoring stack** (`services/monitoring/`): Prometheus, Grafana, AlertManager, exporters (node, PostgreSQL, Redis, systemd, blackbox), cAdvisor
- Secrets managed through sops-nix integration

Services on cubesat live under `hosts/cubesat/services/`:

- **Pangolin**: reverse proxy / tunnel dashboard (enterprise edition; license is activated in the dashboard, not in nix). Runs in "tailnet mode" instead of pangolin's own newt/WireGuard site tunnels: a single local site ("Tailnet") holds all resources, and each target points at a tailnet hostname (`kepler:<port>` from the `k.ports` registry, `homeassistant:8123`, ...), so traefik on cubesat reaches backends directly over Tailscale. This is deliberate and should not be broken. Consequences:
  - Newt-dependent features are inert: `acme_cert_sync` is disabled via `privateConfig.yml` (it would only spam EACCES warnings), and the dashboard's "Network Logs" stay empty (they record newt connection sessions).
  - Authentication/Admin Action/Network log pages are gated by per-org Log Retention settings (Org Settings → General → Security, stored in the DB); retention 0 = logging disabled.
  - If migrating to newt-based sites later, revisit both points above.

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
- **Renovate** (`auto_update = false` + pinned image): third-party images are pinned to `repo:tag@sha256:digest` and bumped via PRs. Renovate-managed services: changedetection, pinchflat, actual, rustypaste, immich, plausible, watchtower, openclaw.

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

- Shared tooling in `lib/restic-backup.nix` (`mkResticBackupService`) drives both hosts identically: `systemd.services.restic-backup`/`restic-backup-preupgrade`/`restic-backup-failure`, `systemd.timers.restic-backup`, and the `backup-restore` CLI (including `backup-restore verify` for a non-destructive restore check) — same names on kepler and cubesat, only the per-host paths/databases passed into the function differ.
- **Kepler**: daily restic backup at 4 AM — native services, Docker volumes (from `k.backup`), PostgreSQL dumps.
- **Cubesat**: daily restic backup at 3 AM — Pangolin data.
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
