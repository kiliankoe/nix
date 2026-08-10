{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/nix/dotfiles/zed";
in
{
  # Out-of-store, because Zed rewrites both files itself whenever a setting
  # changes through the UI. Pointing at the working copy means those writes land
  # straight in git, the same arrangement `claude.nix` uses and for the same
  # reason. Zed stays a Homebrew cask rather than `programs.zed-editor`, so the
  # package isn't managed here — only the config.
  #
  # Zed used to replace the symlink with a regular file on write
  # (zed-industries/zed#4469), which is what made this untested for a while;
  # that was fixed in February 2024 and symlinked config has loaded correctly
  # since. The one open regression is zed-industries/zed#54888: JSON schema
  # autocomplete stops working while editing these two files inside Zed, because
  # the schema's `fileMatch` is tested against the resolved path. Settings
  # themselves still apply, so this costs completions, not correctness.
  xdg.configFile = {
    "zed/settings.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/settings.json";
    "zed/keymap.json".source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/keymap.json";
  };
}
