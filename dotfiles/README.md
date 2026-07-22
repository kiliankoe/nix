# Unmanaged dotfiles

Reference copies of config files that home-manager deliberately does **not** own. Nothing here is read during evaluation; these are snapshots kept for sync across hosts and for history.

## Why not declarative

Home-manager writes `home.file` entries as read-only symlinks into the Nix store. That is correct for files only ever edited by hand, but wrong for apps that rewrite their own config at runtime: the app either fails on the read-only target or replaces the symlink with a regular file, silently detaching it from the config.

| App | Kept here because |
| --- | --- |
| Zed | Installed via Homebrew, not `programs.zed-editor` — the nixpkgs build compiles from source often enough that upgrades cost real time. Zed also rewrites `settings.json` itself whenever settings change through the UI, and its schema moves between releases. |

## Syncing

These are copies, so they drift. Check and refresh manually:

```bash
diff -u dotfiles/zed/settings.json ~/.config/zed/settings.json   # what changed
cp ~/.config/zed/{settings,keymap}.json dotfiles/zed/            # pull live -> repo
cp dotfiles/zed/{settings,keymap}.json ~/.config/zed/            # push repo -> live
```

## Declarative middle ground

For dotfiles that I edit but no app rewrites, `mkOutOfStoreSymlink` links the live path straight at the working copy in this repo, so edits are picked up by git immediately without a rebuild:

```nix
home.file.".foorc".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/foorc";
```

