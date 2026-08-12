# nix

> **This is a living document.** Keep it updated as the project evolves: document new features, record _why_ decisions were made (not just what), and remove or revise anything that becomes outdated. The goal is that anyone (or any AI) can read this file cold and fully understand the project's current state, architecture, and the reasoning behind it.

This is a unified Nix flake configuration managing multiple systems across macOS and NixOS platforms.

See @README.md for the directory structure, host definitions, service management commands, and the backup/restore runbook.

Most modules explain themselves: the "why" behind non-obvious wiring lives as comments next to the code (`home/programs/helix.nix`, `hosts/kepler/systemd.nix`, `hosts/cubesat/services/pangolin.nix` are good examples). Read those before changing a module, and put new reasoning there rather than here. This file covers only what spans multiple files or can't be seen from the code.

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

All hosts are reachable directly by their hostname (e.g. `ssh kepler`) over Tailscale, no IP addresses or `.local` suffixes needed. mosh works everywhere too (`mosh kepler`); its UDP range is opened on `tailscale0` only, since cubesat is WAN-exposed.

- macOS hosts: `darwin-rebuild switch --flake .#<host>`
- NixOS hosts: deploy-rs (`deploy .#<host>`), configured with `remoteBuild` so the x86_64 closure builds on the target; activation prints an nvd package diff
- `./scripts/deploy-with-backup.sh <host>` creates a tagged restic snapshot before deploying

### CI

GitHub Actions (`.github/workflows/`): `check.yml` (flake check, statix, nixfmt, deadnix) and `ci.yml` (evaluates all darwin and nixos configurations), both on push to main and PRs.

`ci.yml` evaluates the darwin configs on a Linux runner on purpose (a macOS runner bills 10x for no added coverage). Consequence: evaluation must never require building a darwin store path, i.e. no IFD (see the `eilmeldung-git` comment in `home/programs/eilmeldung.nix` for the incident that taught this). `nix eval --no-allow-import-from-derivation '.#darwinConfigurations.voyager.config.system.build.toplevel.outPath'` reproduces the failure locally.

## Architecture

Each host imports only the modules it needs. Shared functionality is in `modules/shared/`, platform-specific code in `modules/darwin/` and `modules/nixos/`.

### Port Registry & Service Registration (`modules/shared/k.nix`)

`k.nix` defines the `k` option namespace: `k.ports` (all service ports in one place, to prevent conflicts), `k.monitoring` (services self-register HTTP endpoints, Docker containers, and systemd units for Prometheus), and `k.backup` (Docker volume patterns to include in backups). Reference ports via `config.k.ports.<name>`, never hardcode them.

### Home Manager

User-level programs live in `home/programs/`, one file per tool, imported from `home/darwin.nix` / `home/nixos.nix`; per-host customizations (e.g. git email) live with each host. Things worth knowing that the individual files can't tell you:

- `claude.nix` generates the Claude Code config for both accounts (work `claude`, personal `pcl`) from one source so they can't drift; `settings.json` is an out-of-store symlink into `dotfiles/` (see `dotfiles/README.md`). `claude/command-guard.jq` is a PreToolUse hook that prompts (never denies) on destructive Bash commands; its test suite runs in the build's check phase, so a rule that stops matching fails the build instead of silently no longer prompting. The off-the-shelf alternative [destructive_command_guard](https://github.com/Dicklesworthstone/destructive_command_guard) was evaluated and passed on: it packages fine but is heavy and new.
- `zed.nix` manages only Zed's config, not the package (Homebrew cask); both settings files are out-of-store symlinks into `dotfiles/`. If `~/.config/zed/settings.json` ever becomes a regular file again, Zed has regressed to replacing the link on write ([zed#4469](https://github.com/zed-industries/zed/issues/4469)) and the repo copy is silently going stale.
- `helix.nix` routes js/ts/json formatting through `hx-biome-format` (`home/programs/scripts/hx-biome-format.sh`), which supplies a house style only when the project has no biome or editorconfig opinion. The script header documents the precedence chain and the silent-failure traps around stdin formatting; the nix comments cover the language-server wiring and why every language opts into `auto-format` itself.
- `eilmeldung.nix` (RSS, syncs against freshrss on kepler over the Google Reader API) and `aerc.nix` (mail, fastmail over JMAP; work mail deliberately stays in Outlook) are darwin-only. Packaging and credential gotchas are commented in the files; credentials live in sops under `freshrss/` and `fastmail/`. Alternatives already evaluated for RSS: newsboat (syncs fine but bypasses the home-manager module's structured options) and nom (doesn't sync read/starred state back at all).

### Services

kepler's services live under `hosts/kepler/services/`: native NixOS services at the top level, Docker services in `docker/`, the monitoring stack in `monitoring/`, retired ones in `archived/`.

cubesat runs pangolin and uptime-kuma under `hosts/cubesat/services/`. Pangolin runs in "tailnet mode": a single local site whose resource targets are tailnet hostnames (`kepler:<port>` from the `k.ports` registry, `homeassistant:8123`, ...), so traefik on cubesat reaches backends directly over Tailscale instead of newt/WireGuard tunnels. This is deliberate, don't break it; `pangolin.nix` explains what it makes inert. Not visible from the config: the enterprise license is activated in the dashboard, and the Authentication/Admin Action/Network log pages are gated by per-org Log Retention settings (Org Settings → General → Security; retention 0 = logging disabled).

Adding a service:

- Docker: use `mkDockerComposeService` from `lib/docker-service.nix` (options documented in the file), following `hosts/kepler/services/docker/linkding.nix`. It generates `compose.yml`/`.env` under `/etc/docker-compose/<name>/`, auto-declares sops secrets from `{ secret = "name"; }` environment values, registers monitoring and backups in `k.*`, and sets `restartTriggers` so a deploy that changes the compose file actually restarts the service.
- Native: follow `hosts/kepler/services/freshrss.nix` or `paperless.nix`.
- If it touches a NAS path (`/mnt/media`, `/mnt/photos/immich`): add its systemd unit name to the mount's `consumers` list in `hosts/kepler/systemd.nix` (for Docker services that's the `serviceName`). `mkCifsMount` derives all mount/service ordering from that one list; the comments there explain each dependency edge. Never hand-write mount ordering elsewhere — a service writing to `/mnt/media` with no mount dependency is exactly the drift that motivated the helper.

### Docker Image Updates

Each Docker service uses exactly one of two mechanisms:

- watchtower (`auto_update = true`): auto-pulls new images for labelled containers. Used for the first-party `kiliankoe/*` images plus linkding. watchtower itself must stay `auto_update = false`: updating its own container can cancel an in-flight update batch and leave other containers stopped.
- Renovate (`auto_update = false`): third-party images are pinned to `repo:tag@sha256:digest` and bumped via PRs. Opt-in per image: add a `# renovate` comment line directly above the `image =` line; the customManager in `renovate.json` only matches marked lines. Database images (postgres, clickhouse, valkey) are excluded from automatic major bumps.

Renovate runs as the hosted [Mend Renovate](https://github.com/apps/renovate) GitHub App, event-driven on its own schedule; there is no in-repo workflow or secret to maintain.

### Flake Input Updates

Renovate's `nix` manager is enabled but gated behind `dependencyDashboardApproval`: input bumps only appear as checkboxes on the Dependency Dashboard issue, never as unattended PRs. Manual `nix flake update` plus a local `nh build` is deliberately the primary flow, because it builds the closure and shows the diff, which the eval-only PR checks can't; the dashboard covers the away-from-keyboard case and doubles as a staleness view. `minimumReleaseAge` is zeroed for the nix manager (the global 7-day gate is meant for Docker releases). The `ssh-keys` file input carries no `rev` and is skipped by Renovate; only a manual `nix flake update` refreshes it. Ticking a checkbox makes the App run `nix flake update <input>` on Mend's runners — unverified until the first ticked box; if the PR never appears, that's where to look.

### Secrets

Encrypted in `secrets/secrets.yaml` via sops-nix, edited with `sops secrets/secrets.yaml` (age key at `~/.config/sops/age.key`). sops-nix populates `/run/secrets/` during activation, not via a systemd service — there is no `sops-nix.service` to depend on.

### Monitoring

Prometheus (30-day retention) scrapes everything registered through `k.monitoring`; Grafana dashboards and AlertManager email alerts are provisioned in `hosts/kepler/services/monitoring/`, alongside the node/PostgreSQL/Redis/systemd/blackbox exporters and cAdvisor.

When registering `httpEndpoints`, use `0.0.0.0` or `127.0.0.1` in the probe URL, never `localhost`: the blackbox exporter's http prober prefers IPv6, `localhost` resolves to `::1`, the services only listen on IPv4, and `EndpointDown` fires for a service that is actually healthy. `ip_protocol_fallback` only covers DNS resolution, not a refused connection.

### Backups

`lib/restic-backup.nix` (`mkResticBackupService`) drives both hosts identically: same systemd units, timers, and `backup-restore` CLI on kepler (daily 4 AM: native services, Docker volumes from `k.backup`, PostgreSQL dumps) and cubesat (daily 3 AM: pangolin and uptime-kuma). SFTP backend, healthchecks.io failure notifications, 7 daily / 4 weekly / 6 monthly retention. Usage, restore workflow, and `backup-restore verify` are documented in @README.md.

### Package Management

`allowUnfree = true` globally. Packages are organized per host; macOS GUI apps are Homebrew casks (`modules/darwin/homebrew.nix` shared, `hosts/<hostname>/homebrew.nix` per host).

#### Container Runtime on macOS

Both macOS hosts share the docker CLIs (`modules/shared/packages-docker.nix`, also imported by kepler, so nothing macOS-specific belongs in that file) but deliberately run different daemons: voyager (personal) uses OrbStack (cask in `hosts/voyager/homebrew.nix`), cassini (work) uses colima (`modules/darwin/colima.nix`), because OrbStack and Docker Desktop are free for personal use only while colima is MIT and speaks the same socket. The launchd quirks are commented in `colima.nix`. Not visible from the config: resource limits are tuned imperatively (`colima start --cpu 4 --memory 8` persists to `~/.colima/default/colima.yaml`), logs land in `~/Library/Logs/colima.log`, and `docker-credential-helpers` is packaged because the unmanaged `~/.docker/config.json` still says `"credsStore": "osxkeychain"` from the OrbStack days and the docker CLI shells out to that helper for private registry auth.
