# Unmanaged dotfiles

Config files whose _contents_ home-manager deliberately does **not** own, because the app rewrites them itself at runtime. Nothing here is read during evaluation.

Every file here is linked into place with `mkOutOfStoreSymlink`, so the live path _is_ the file in this repo. There is no sync step: changing a setting in the app shows up as a plain diff, and `git status` after the change is the whole workflow.

## Why not in the store

Home-manager writes `home.file` entries as read-only symlinks into the Nix store. That is correct for files only ever edited by hand, but wrong for apps that rewrite their own config at runtime: the app either fails on the read-only target or replaces the symlink with a regular file, silently detaching it from the config.

| App | Kept here because | Linked from |
| --- | --- | --- |
| Zed | Rewrites `settings.json` itself whenever settings change through the UI, and its schema moves between releases. Installed via Homebrew rather than `programs.zed-editor`, because the nixpkgs build compiles from source often enough that upgrades cost real time, so only the config is managed. | `home/programs/zed.nix` |
| Claude Code | `/config` and in-session toggles (theme, model, plugins, notification channel) rewrite `settings.json`. Everything else about it is managed normally, in `home/programs/claude/`. Both accounts point at this one file, so they can't drift from each other. | `home/programs/claude.nix` |

## How the link works

`mkOutOfStoreSymlink` points the live path straight at the working copy in this repo, so edits are picked up by git immediately without a rebuild, and the target stays writable:

```nix
home.file.".foorc".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/foorc";
```

Both forms of `home.file` produce a symlink; the difference is what it points at. The default `source = ./foo` copies into `/nix/store` and links there, and the store is read-only, so an app that rewrites its own config gets `EACCES` or clobbers the link. `mkOutOfStoreSymlink` points at a writable file instead.

`xdg.configFile` takes the same `.source` and is the right entry point for anything under `~/.config`. It works regardless of `xdg.enable`, which is off here.

## Before adding an app

This only works if the app writes _through_ the link. An app doing atomic write-and-rename replaces the symlink with a regular file and silently detaches it, so check that first. Both current entries were checked, and each depends on something worth re-testing after a major upgrade:

## Fallback: plain copies

Only for an app that turns out to replace the link rather than write through it. Nothing currently uses this, and it should stay that way, because a copy drifts the moment you forget to run it.

If it's unavoidable, drop the `home.file` entry entirely so the app owns the live path, keep the copy here for history, and sync by hand:

```bash
diff -u dotfiles/<app>/settings.json ~/.config/<app>/settings.json   # what changed
cp ~/.config/<app>/settings.json dotfiles/<app>/                     # pull live -> repo
cp dotfiles/<app>/settings.json ~/.config/<app>/                     # push repo -> live
```
