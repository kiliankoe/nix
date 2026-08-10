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

- Programs (zsh, tmux, git, ghostty, helix, k9s, lazygit, zed, starship, direnv, zoxide, sops-env, claude, eilmeldung, aerc) in `home/programs/`
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
  - It is not in nixpkgs. Upstream ships its own flake, so the input provides both the package and the home-manager module (`inputs.eilmeldung.homeManager.default`, note the attr is `homeManager`, not `homeManagerModules`). The module's `package` default is `pkgs.eilmeldung`, which only exists via upstream's overlay; setting `package` from `inputs.eilmeldung.packages.<system>.<attr>` gets the same derivation without applying an overlay globally.
  - That attr must be `eilmeldung-git`, not `default`. The two build identically and differ only in `src`: `default` re-fetches the tagged release with `fetchFromGitHub`, and upstream's `cargoLock.lockFile = "${src}/Cargo.lock"` then reads a file out of that derivation, which is IFD. Evaluating the darwin configs therefore had to *build* an `aarch64-darwin` path, and `ci.yml` evaluates them on a Linux runner on purpose (a macOS runner bills 10x for no added coverage), so CI failed with `platform mismatch`. `eilmeldung-git` takes the flake input's own source tree, already a store path, so nothing is realised during eval. Consequence: the packaged version follows the input's locked rev (`nix flake update eilmeldung`) rather than upstream's release tag, and the derivation is named after the short rev instead of a version number. Guard against a regression here with `nix eval --no-allow-import-from-derivation '.#darwinConfigurations.voyager.config.system.build.toplevel.outPath'`, which reproduces the CI failure locally on darwin.
  - The freshrss credential is the *API password* from the freshrss profile, a separate value from the account password, and API access has to be enabled in freshrss's authentication settings. It lives in sops as `freshrss/api_password`.
  - Secrets marked `cmd:` are run through `Command::new`, not a shell, so `SOPS_AGE_KEY_FILE=… sops …` would be read as a binary name. Hence the `writeShellScript` wrapper that exports the variable and then execs sops. The generated config only ever contains that store path, never the password.
  - Alternatives evaluated: newsboat syncs correctly too and is in nixpkgs, but with `urls-source "freshrss"` the home-manager module's structured `urls`/`queries` options go unused and everything ends up in `extraConfig`. nom was rejected outright: its freshrss "backend" only calls `ClientLogin` and `subscription/list` to import the feed list, then fetches feeds from the origin and keeps read/starred state in local SQLite, so nothing syncs back.
- `aerc.nix` is the terminal mail client, imported from `home/darwin.nix` so it lands on both macOS hosts. It talks to fastmail over JMAP rather than IMAP, which is what fastmail itself recommends and what lets `outgoing = jmap://` reuse the incoming connection, so one API token covers both directions. Work mail deliberately stays in Outlook. Details worth not re-deriving:
  - `withNotmuch` (the package default) has to be turned off. It pulls in notmuch → emacs → mailutils, and mailutils 3.21 fails to link on aarch64-darwin (undefined `mu_url_*` symbols). The upstream binary cache does not carry aerc for darwin at every nixpkgs bump either, so this is a real local build, not a substituted one. Nothing is lost: JMAP searches server-side, so the notmuch backend would be dead weight. If notmuch is ever wanted, `notmuch.override { withEmacs = false; }` avoids the same chain.
  - `general.unsafe-accounts-conf = true` is mandatory, not a shortcut. aerc refuses to read an `accounts.conf` that isn't 0600, and home-manager writes it into the store at 0444. It stays safe because both credentials come from `source-cred-cmd`/`carddav-source-cred-cmd`, so the file holds store paths of scripts, never a token.
  - Two separate fastmail credentials, both in sops under `fastmail/`: `api_token` is an API token with mail scope (created at app.fastmail.com/settings/security/tokens), `carddav_password` is an app password limited to CardDAV. They are different credential types and cannot be shared.
  - `address-book-cmd` passes `-c` explicitly because `carddav-query` hardcodes `~/.config/aerc/accounts.conf`, while home-manager's aerc module writes to `~/Library/Preferences/aerc` on darwin whenever `xdg.enable` is false (which is also where aerc itself looks, so only carddav-query needs telling).
  - `cache-blobs` stays off. It caches message bodies and attachments indefinitely and upstream expects a cron job to prune it; `cache-state` (metadata) is on and self-managing.
  - The `[filters]` block is copied verbatim from the package's `share/aerc/aerc.conf` and has to stay. aerc reads the first `aerc.conf` it finds and does not merge, so home-manager writing one shadows the shipped file, and filters are the only settings in it that aren't compiled-in defaults. Drop them and every message part shows "No filter configured for this mimetype". Filter order is first-match-wins while home-manager sorts keys alphabetically, so adding a wildcard (`text/*`) would sort ahead of `text/calendar`, `text/html` and `text/plain` and swallow them.
  - home-manager's `accounts.email` integration is not used: its aerc generator only emits notmuch, maildir, imap and smtp sources, so a JMAP account has to go through `programs.aerc.extraAccounts` as raw INI anyway.
- `helix.nix` formats js/jsx/ts/tsx/json/jsonc with biome through the `hx-biome-format` wrapper (`scripts/hx-biome-format.sh`), and markdown with prettier because biome doesn't support it. The wrapper exists to make spaces the default without overriding projects that decided otherwise. Details worth not re-deriving:
  - biome indents with **tabs** by default and has no user-level config file. `--config-path` replaces project discovery rather than layering beneath it, and a `~/.editorconfig` is useless because biome's upward search starts at the working directory. So the only place a personal default can live is a wrapper.
  - The wrapper cannot just pass `--indent-style=space` unconditionally: CLI flags outrank `biome.json`, so a project that deliberately picked tabs would be silently reformatted. It walks up from `$PWD` instead and supplies the flag only when neither `biome.json`/`biome.jsonc` nor `.editorconfig` is found, giving `biome.json` > `.editorconfig` > space > biome's tab. `.editorconfig` needs `--use-editorconfig=true` to be read at all (it defaults off), and `biome.json` still wins over it.
  - Searching from `$PWD` is correct because helix runs formatters with the _document's_ directory as cwd, which is exactly where biome starts its own upward search. Verified by pointing helix's formatter at a script that logged `$PWD`.
  - The formatter arg is `%sh{basename %{buffer_name}}`, not `%{buffer_name}`. helix expands command-line variables in formatter args, but `buffer_name` is relative to helix's cwd while the formatter runs in the document's directory, so passing it whole yields a doubled path. Worse, when biome is handed a path that reaches into a subtree owning its own `biome.json`, it aborts with "Found a nested root configuration" (exit 1, empty stdout) instead of formatting. The bare basename sidesteps both and still lets biome pick the parser and match `files.includes`.
  - `just-formatter` is a separate package because `just --fmt` overwrites in place and sits behind `--unstable`, while helix formatters must read stdin and write stdout. helix's bundled `languages.toml` has the same entry commented out, pointing at helix issue 9703.
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

#### Container Runtime on macOS

The two macOS hosts deliberately run different docker daemons, because the licensing differs and only one of them is a work machine. The `docker` and `docker-compose` CLIs are the same on both, from `modules/shared/packages-docker.nix` (also imported by kepler, which is why nothing macOS-specific belongs in that file).

- **voyager** (personal): OrbStack, cask in `hosts/voyager/homebrew.nix`. It used to live in the shared `modules/darwin/homebrew.nix`; it was moved out precisely so cassini stops inheriting it.
- **cassini** (work): colima, via `modules/darwin/colima.nix`, imported only from `hosts/cassini/default.nix`.

Docker Desktop and OrbStack are both free for personal use only and need a paid plan for commercial use, so neither is licensable on cassini. colima is MIT, headless, and speaks the same socket, so everything downstream (`dive`, the `dockerpwd` alias in `home/programs/zsh.nix`) is unaffected. Details worth not re-deriving:

- The `launchd.user.agents.colima` command needs `--foreground`. Without it `colima start` daemonises and returns, and launchd reaps the job the moment it does.
- The agent's `path` is only the system dirs. colima's nixpkgs wrapper already prepends limactl/docker/qemu/krunkit, but lima reaches the VM over `ssh`, which a launchd agent won't otherwise find. Its `EnvironmentVariables.PATH` replaces the inherited PATH rather than extending it, so dropping those breaks the VM start rather than colima itself.
- `KeepAlive.SuccessfulExit = false` restarts colima if it crashes while leaving a deliberate `colima stop` stopped.
- colima defaults to `--vm-type=vz` (Apple Virtualization), so there is no qemu in the running path despite qemu being on the wrapper's PATH.
- Resource limits are not set in nix on purpose. colima defaults to 2 CPU / 2 GiB / 60 GiB; `colima start --cpu 4 --memory 8` persists to `~/.colima/default/colima.yaml` (`--save-config` defaults true), so tuning survives without the flags entering the module.
- colima sets itself as the active Docker context on start. The old `desktop-linux` and `orbstack` contexts in `~/.docker/contexts/` are user state that nix does not manage and were removed by hand.
- Logs land in `~/Library/Logs/colima.log`.
- `pkgs.docker-credential-helpers` ships alongside colima for the same reason: `~/.docker/config.json` carries `"credsStore": "osxkeychain"` from the Docker Desktop/OrbStack days, and the docker CLI shells out to `docker-credential-osxkeychain` for private registry auth (e.g. `pnpm docker:up` pulling from an ACR). Docker Desktop and OrbStack both bundled that helper; colima doesn't, so removing them left the config pointing at a binary that no longer existed.
