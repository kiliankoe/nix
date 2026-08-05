# Unmanaged dotfiles

Reference copies of config files that home-manager deliberately does **not** own. Nothing here is read during evaluation; these are snapshots kept for sync across hosts and for history.

## Why not declarative

Home-manager writes `home.file` entries as read-only symlinks into the Nix store. That is correct for files only ever edited by hand, but wrong for apps that rewrite their own config at runtime: the app either fails on the read-only target or replaces the symlink with a regular file, silently detaching it from the config.

| App | Kept here because |
| --- | --- |
| Zed | Installed via Homebrew, not `programs.zed-editor` — the nixpkgs build compiles from source often enough that upgrades cost real time. Zed also rewrites `settings.json` itself whenever settings change through the UI, and its schema moves between releases. |
| Claude Code | `/config` and in-session toggles (theme, model, plugins, notification channel) rewrite `settings.json`, so it can't live in the read-only store. It is still linked declaratively — see below — so the live file _is_ this file. Everything else is managed, in `home/programs/claude/`. Both accounts point at this one copy, so they can't drift. |

## Syncing

These are copies, so they drift. Check and refresh manually:

Zed's copies drift, so check and refresh manually:

```bash
diff -u dotfiles/zed/settings.json ~/.config/zed/settings.json   # what changed
cp ~/.config/zed/{settings,keymap}.json dotfiles/zed/            # pull live -> repo
cp dotfiles/zed/{settings,keymap}.json ~/.config/zed/            # push repo -> live
```

Claude Code's needs none of this — it's linked, not copied, so changing a
setting in-session shows up as a plain diff in this repo. `git status` after a
`/config` change is the whole workflow.

## Declarative middle ground

`mkOutOfStoreSymlink` links the live path straight at the working copy in this repo, so edits are picked up by git immediately without a rebuild, and the target stays writable:

```nix
home.file.".foorc".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/foorc";
```

Both forms of `home.file` produce a symlink; the difference is what it points at. The default `source = ./foo` copies into `/nix/store` and links there, and the store is read-only — an app that rewrites its own config gets `EACCES`, or clobbers the link. `mkOutOfStoreSymlink` points at a writable file instead, so that class of app works, provided it writes *through* the link rather than replacing it. Apps doing atomic write-and-rename replace the symlink with a regular file and silently detach it; check before relying on this. Claude Code handles the case explicitly (`allowSymlink` on user settings), Zed is untested.

