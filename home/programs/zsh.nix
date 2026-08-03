{ pkgs, ... }:
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

    # A plain `compinit` runs compaudit, which stats every file in $fpath. That
    # is ~80% of rc-phase startup cost and the main reason cold starts took
    # seconds. `-C` skips both compaudit and the dump staleness check, so the
    # dump filename carries what would otherwise be rechecked every time:
    #
    #   - $ZSH_VERSION, because $fpath is version-interpolated and macOS ships
    #     5.9 as the login shell while nix provides 5.9.2. Sharing one dump made
    #     the two versions invalidate each other's on every alternation.
    #   - the system generation, since nix store paths all carry epoch mtimes
    #     and so can't be compared with -nt.
    #
    # A rebuild then costs one shell per switch (or brew completion change)
    # instead of one fpath walk per shell.
    completionInit =
      let
        # brew installs completions without changing the nix generation, so this
        # one needs a real mtime check; every other $fpath source is nix-managed
        # and so already covered by the generation in the dump name.
        brewCompletions = "/opt/homebrew/share/zsh/site-functions";
      in
      ''
        _zcompdump_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        _zcompdump="$_zcompdump_dir/zcompdump-$ZSH_VERSION-''${''${:-/run/current-system}:A:t}"
        [[ -d $_zcompdump_dir ]] || mkdir -p $_zcompdump_dir

        autoload -U compinit
        if [[ -f $_zcompdump && ( ! -e ${brewCompletions} || $_zcompdump -nt ${brewCompletions} ) ]]; then
          compinit -C -d "$_zcompdump"
        else
          # Scoped to this zsh version: wiping every dump would delete the dump
          # the other version just built for this generation, and the two would
          # rebuild each other's away on every alternation.
          rm -f "$_zcompdump_dir"/zcompdump-$ZSH_VERSION-*(N)
          compinit -d "$_zcompdump"
        fi
        unset _zcompdump_dir _zcompdump
      '';

    shellAliases = {
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
      zshreload = "exec zsh -l";
      pcl = "CLAUDE_CONFIG_DIR=~/.claude-personal claude";
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
    initContent =
      pkgs.lib.optionalString (!pkgs.stdenv.isDarwin) ''
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

      ''
      + pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
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

        # atuin initialization
        if command -v atuin >/dev/null 2>&1; then
          eval "$(atuin init zsh --disable-up-arrow)"
        fi
      '';

    # Platform-specific zsh opts are in darwin.nix and nixos.nix
  };
}
