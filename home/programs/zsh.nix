{
  lib,
  pkgs,
  ...
}:
{
  # Install tmux helper script for copying last command output
  home.file.".local/bin/tmux-copy-last-output" = {
    source = ./scripts/tmux-copy-last-output.sh;
    executable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # compinit is the expensive part of startup: a plain run compaudits every
    # file in $fpath (~1300 here) and rebuilds the dump. `-C` skips all of
    # that but trusts the dump blindly, so validity is guaranteed by the dump
    # filename instead. Nix store mtimes are all epoch, so `-nt` checks can't
    # detect staleness; the name carries what could invalidate the dump:
    #
    #   - the system generation, which changes whenever nix-managed
    #     completions can change
    #   - $ZSH_VERSION, because $fpath is version-interpolated and macOS's
    #     /bin/zsh coexists with nix's zsh, each needing its own dump
    #
    # When the exact dump is missing or stale (typically the first shell
    # after a switch, historically a multi-second blank pane right when the
    # machine is busiest), the shell starts instantly from the newest
    # previous dump and rebuilds the real one in a disowned subshell. A
    # forked subshell inherits the exact interactive $fpath, which a
    # re-exec'd zsh would not reliably reproduce. Only a shell that finds no
    # dump at all pays a full foreground rebuild.
    completionInit =
      let
        # brew installs completions without changing the nix generation, so
        # this one $fpath source needs a real mtime check (brew bumps the dir
        # mtime on install/uninstall).
        brewCompletions = "/opt/homebrew/share/zsh/site-functions";
      in
      ''
        _zcompdump_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        _zcompdump="$_zcompdump_dir/zcompdump-$ZSH_VERSION-''${''${:-/run/current-system}:A:t}"
        [[ -d $_zcompdump_dir ]] || mkdir -p $_zcompdump_dir

        autoload -U compinit
        if [[ -f $_zcompdump && ( ! -e ${brewCompletions} || $_zcompdump -nt ${brewCompletions} ) ]]; then
          _zsh_startup_compinit_mode=fast
          compinit -C -d "$_zcompdump"
        else
          _zcompdump_stale=("$_zcompdump_dir"/zcompdump-$ZSH_VERSION-*(N.om))
          if (( $#_zcompdump_stale )); then
            _zsh_startup_compinit_mode=stale
            compinit -C -d "$_zcompdump_stale[1]"
            (
              # Loading the stale dump above populated the comp tables; clear
              # them so its entries can't leak into the fresh dump.
              _comps=() _services=() _patcomps=() _postpatcomps=() _compautos=()
              compinit -d "$_zcompdump"
              # Old dumps are this fast path, so drop them only once the new
              # one exists. compdump writes tempfile+mv, so a concurrent shell
              # never sees a partial dump.
              if [[ -f $_zcompdump ]]; then
                for _f in "$_zcompdump_dir"/zcompdump-$ZSH_VERSION-*(N); do
                  # `command` so this stays independent of where home-manager
                  # emits the interactive `rm -I` alias relative to this block.
                  [[ $_f == $_zcompdump ]] || command rm -f "$_f"
                done
              fi
            ) < /dev/null &> /dev/null &!
          else
            _zsh_startup_compinit_mode=full
            compinit -d "$_zcompdump"
          fi
        fi
        unset _zcompdump_dir _zcompdump _zcompdump_stale
        typeset -gF _zsh_startup_t_compinit=$EPOCHREALTIME
      '';

    shellAliases = {
      l = "eza -la";
      ta = "tmux attach || tmux new";
      df = "df -H";
      du = "du -ch";
      nch = "nixfmt **/*.nix && statix check . && deadnix --fail";
      rsync = "rsync --progress";
      cdtmp = "cd $TMPDIR";
      tree = "tree -C";
      lf = "/bin/ls -rt | tail -n1";
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      dockerpwd = "docker run --rm -it -v $(PWD):/src";
      # One confirmation for a recursive delete or >3 files, instead of -i's
      # per-file nagging that just trains reflexive `y`. BSD rm honours -I even
      # when -f follows, so `rm -rf` still prompts on darwin; GNU rm lets the
      # later -f win, so on the linux hosts this only covers deletes without -f.
      rm = "rm -I";
    };

    history = {
      size = 20000;
      save = 20000;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    # unfortunately zsh.sessionVariables or zsh.localVariables doesn't appear to be working
    initContent = lib.mkMerge [
      # Startup instrumentation, part 1: t0 as early as the rc allows (order
      # 500 lands before completionInit). Slow startups here have been
      # intermittent and hard to reproduce after the fact, so every shell
      # measures itself and only slow ones leave a trace.
      (lib.mkOrder 500 ''
        zmodload zsh/datetime
        typeset -gF _zsh_startup_t0=$EPOCHREALTIME
        typeset -gF _zsh_startup_t_compinit=$_zsh_startup_t0 _zsh_startup_t_rc=$_zsh_startup_t0
        typeset -g _zsh_startup_compinit_mode=none
      '')

      (
        lib.optionalString (!pkgs.stdenv.isDarwin) ''
          # Auto-attach to tmux for interactive shells (set NO_TMUX=1 to bypass)
          if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [[ $- == *i* ]] && [ -z "$NO_TMUX" ]; then
            exec tmux new-session -A -s main
          fi
        ''
        + ''
          # User-local binaries
          export PATH="$HOME/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

          # Case-insensitive completion, plus partial-word and substring matching.
          zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

          # zsh already queries before `rm *` / `rm path/*`; this also makes it
          # discard keystrokes for ten seconds, so a queued or pasted `y` can't
          # answer the prompt before it's been read. Tab-expanding the `*` skips
          # both the wait and the query.
          setopt RM_STAR_WAIT

          # Session variables
          export REPORTTIME="5"
          export LESS="--mouse"
          export NH_FLAKE="$HOME/nix"

          glogs() {
            local job_name="$1"

            if [ -z "$job_name" ]; then
              echo "Usage: glogs <job-name>"
              return 1
            fi

            local mr_iid
            mr_iid="$(glab mr view --output json | jq -r '.iid')" || return 1

            local pipeline_id
            pipeline_id="$(glab api "projects/:id/merge_requests/$mr_iid/pipelines" \
              | jq -r 'max_by(.id).id')" || return 1

            glab ci trace -p "$pipeline_id" "$job_name"
          }

          jira() {
            if (( $# < 2 )); then
              print -u2 "Usage: jira <project> <text> [acli flags...]"
              return 1
            fi

            local project=''${1:u} text=$2
            shift 2

            # JQL string literals take backslash escapes; an unescaped quote in
            # the search term ends the literal early and yields a parse error.
            text=''${text//\\/\\\\}
            text=''${text//\"/\\\"}

            acli jira workitem search \
              --jql "project = $project AND text ~ \"$text\" ORDER BY created DESC" \
              "$@"
          }

        ''
        + lib.optionalString pkgs.stdenv.isDarwin ''
          export ICLOUD_DRIVE="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
        ''
        + ''

          # Load sops-managed environment variables
          if [[ -f "$HOME/.config/sops/env.sh" ]]; then
            source "$HOME/.config/sops/env.sh"
          fi

          # Load deno environment if it exists (will work for any user)
          if [[ -f "$HOME/.deno/env" ]]; then
            source "$HOME/.deno/env"
          fi

          # Functions
          function mkcd() { mkdir -p "$1" && cd "$1"; }

          # Ctrl-Z as a toggle: the tty suspends a foreground job on Ctrl-Z,
          # this makes the same key at the prompt resume it, keeping me from
          # having to type `fg` (yeah, big gain, I know).
          # This also allows temporary stashing typed input into the prompt.
          ctrl-z-toggle() {
            if [[ -z $BUFFER ]]; then
              BUFFER="fg"
              zle accept-line
            else
              zle push-input
            fi
          }
          zle -N ctrl-z-toggle
          bindkey '^Z' ctrl-z-toggle

          # A function rather than an alias, because `exec` replaces the shell
          # and the job table lives in that process image: anything suspended
          # (usually a C-z'd editor) survives as an orphan still parented to
          # this PID, but unreachable by `fg` and holding no shell's attention.
          # zsh/parameter is loaded here rather than at rc time so a shell that
          # never reloads doesn't pay for it.
          zshreload() {
            zmodload zsh/parameter
            if (( $#jobstates )); then
              print -u2 "zshreload: refusing, these jobs would be orphaned:"
              jobs -l >&2
              return 1
            fi
            exec zsh -l
          }

          soma() {
            if (( $# )); then
              somafm play --quality=highest "$@"
              return
            fi

            local channel
            # No `local channel=$(...)`: `local` always exits 0, which would
            # swallow fzf's 130 on Esc and play whatever `$\{channel%% *}` is.
            channel=$(somafm ls | fzf --height=40% --reverse) || return
            somafm play --quality=highest "''${channel%% *}"
          }

          # atuin initialization
          if command -v atuin >/dev/null 2>&1; then
            eval "$(atuin init zsh --disable-up-arrow)"
          fi
        ''
      )

      # Startup instrumentation, part 2: order 3000 lands after the tool
      # integrations (starship, direnv, ...), so the one-shot precmd below is
      # registered last and runs after their first hooks. Shells slower than
      # ZSH_STARTUP_LOG_MS (default 1000) to the first prompt append a phase
      # breakdown to ~/.cache/zsh/slow-start.log: "compinit" is the completion
      # setup, "rc" the rest of the rc files, "prompt" the first round of
      # precmd hooks including starship's initial render.
      (lib.mkOrder 3000 ''
        typeset -gF _zsh_startup_t_rc=$EPOCHREALTIME
        _zsh_startup_report() {
          local -F now=$EPOCHREALTIME
          add-zsh-hook -d precmd _zsh_startup_report
          local -i total_ms=$(( (now - _zsh_startup_t0) * 1000 ))
          if (( total_ms >= ''${ZSH_STARTUP_LOG_MS:-1000} )); then
            local -i compinit_ms=$(( (_zsh_startup_t_compinit - _zsh_startup_t0) * 1000 ))
            local -i rc_ms=$(( (_zsh_startup_t_rc - _zsh_startup_t_compinit) * 1000 ))
            local -i prompt_ms=$(( (now - _zsh_startup_t_rc) * 1000 ))
            local ts
            strftime -s ts '%F %T' $EPOCHSECONDS
            print -r -- "$ts pid=$$''${TMUX:+ tmux} gen=''${''${:-/run/current-system}:A:t} mode=$_zsh_startup_compinit_mode total=''${total_ms}ms compinit=''${compinit_ms}ms rc=''${rc_ms}ms prompt=''${prompt_ms}ms" \
              >> "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/slow-start.log"
          fi
          unset _zsh_startup_t0 _zsh_startup_t_compinit _zsh_startup_t_rc _zsh_startup_compinit_mode
          unfunction _zsh_startup_report
        }
        autoload -U add-zsh-hook
        add-zsh-hook precmd _zsh_startup_report
      '')
    ];

    # Platform-specific zsh opts are in darwin.nix and nixos.nix
  };
}
