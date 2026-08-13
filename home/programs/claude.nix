{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.k.claude;

  # PreToolUse hook for Bash calls. The permission rules in settings.json match a
  # literal command prefix, so `Bash(rm -rf:*)` sees `rm -rf` and misses `rm -fr`,
  # `rm -r -f` and `sudo rm -rf`. This parses the command into tokens instead, so
  # flag spelling and order stop mattering, and it splits on shell operators so a
  # command hiding behind `&&` is judged on its own.
  #
  # It answers "ask", never "deny": a false positive costs one keystroke, a false
  # deny costs a wedged session. Nothing is given up by that — Claude Code still
  # evaluates the deny rules in settings.json regardless of what a hook returns,
  # so those stay the hard backstop underneath.
  commandGuard = pkgs.writeShellApplication {
    name = "claude-command-guard";
    runtimeInputs = [ pkgs.jq ];

    # A jq failure (malformed payload, a jq upgrade breaking a construct) must
    # not break the session, so it exits 0 with no decision and lets the normal
    # permission flow take over.
    text = ''
      jq -c -f ${./claude/command-guard.jq} || exit 0
    '';

    derivationArgs = {
      nativeBuildInputs = [ pkgs.jq ];
      # Runs as part of the build's check phase, so a rule that stops matching
      # fails the build rather than surfacing as a hook that quietly stopped
      # prompting. The `pass` half of the suite is what keeps it from prompting
      # on ordinary work and getting clicked through on reflex.
      postCheck = ''
        sh ${./claude/command-guard-test.sh} \
          ${./claude/command-guard.jq} \
          ${./claude/command-guard-tests.txt}
      '';
    };
  };

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
    # settings.json points the hook at this by absolute path, so it has to be
    # installed anywhere claude.nix is. A missing hook binary exits 127, which
    # Claude Code treats as a non-blocking error, i.e. the guard would fail open
    # silently on any host that had settings.json but not this.
    home.packages = [ commandGuard ];

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
      #
      # manual-mode.json uses a single `Edit` ask rule (not deny) so explicitly
      # delegated edits stay possible behind a per-edit prompt that survives
      # acceptEdits/bypassPermissions. `Edit` rules cover Write and NotebookEdit
      # too; separate ask entries for those are ignored with a startup warning.
      shellGlobalAliases."--manual" =
        "--settings ${./claude/manual-mode.json} --append-system-prompt-file ${./claude/manual-mode.md}";
    };
  };
}
