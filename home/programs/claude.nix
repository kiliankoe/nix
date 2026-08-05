{ config, lib, ... }:
let
  cfg = config.k.claude;

  # Claude Code runs under two accounts that only differ by CLAUDE_CONFIG_DIR.
  # Everything below is meant to be identical for both, so it's generated from
  # one source.
  sharedFiles = {
    "CLAUDE.md".source = ./claude/CLAUDE.md;
    "commands/review-mr.md".source = ./claude/commands/review-mr.md;
    "skills/humanizer".source = ./claude/skills/humanizer;

    # Out-of-store, unlike everything above, because Claude Code rewrites this
    # file itself (/config, model switches, plugin toggles) and the store is
    # read-only. Pointing at the working copy means those writes land straight
    # in git; both accounts share the one file, so they can't drift.
    #
    # This relies on Claude Code passing `allowSymlink: true` when writing user
    # settings — it resolves the link and renames onto the real target. Project
    # and local settings get `allowSymlink: false` instead, so if an upgrade
    # ever flips user settings too, writes start failing with "Refusing to
    # write through symlink" and this has to go back to a plain copy.
    "settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/dotfiles/claude/settings.json";
  };

  # ~/.claude is whatever account this machine primarily uses, so it stays the
  # default CLAUDE_CONFIG_DIR. Anything invoking `claude` without going through
  # an interactive shell alias (scripts, editor extensions, launchd) then still
  # lands in a logged-in account rather than a blank, unauthenticated one.
  configDirs = [ ".claude" ] ++ lib.optional (cfg.personalConfigDir != null) cfg.personalConfigDir;
in
{
  options.k.claude.personalConfigDir = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = ".claude-personal";
    description = ''
      Config dir for the personal account, relative to $HOME, on hosts whose
      primary account is not the personal one. Null means personal is already
      ~/.claude, so `pcl` is a plain passthrough to `claude`.
    '';
  };

  config = {
    home.file = lib.listToAttrs (
      lib.concatMap (
        dir: lib.mapAttrsToList (path: attrs: lib.nameValuePair "${dir}/${path}" attrs) sharedFiles
      ) configDirs
    );

    programs.zsh = {
      # `pcl` means "the personal account" on every host, so muscle memory works
      # everywhere and can never open an unauthenticated config dir.
      shellAliases.pcl =
        if cfg.personalConfigDir == null then
          "claude"
        else
          "CLAUDE_CONFIG_DIR=~/${cfg.personalConfigDir} claude";

      # A global alias (expands anywhere on the line, not just in command
      # position) so the mode composes with both entry points instead of needing
      # a claude/pcl variant each: `claude --manual`, `pcl --manual`.
      #
      # --settings layers onto the account's own settings rather than replacing
      # them. --append-system-prompt-file works but isn't listed in --help, so
      # re-check it if a Claude Code upgrade makes the mode look inert.
      shellGlobalAliases."--manual" =
        "--settings ${./claude/manual-mode.json} --append-system-prompt-file ${./claude/manual-mode.md}";
    };
  };
}
