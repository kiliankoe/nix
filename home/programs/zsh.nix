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

    shellAliases = {
      ta = "tmux attach || tmux new";
      df = "df -H";
      du = "du -ch";
      lg = "lazygit";
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
    initContent = ''
      # User-local binaries
      export PATH="$HOME/bin:$HOME/.bun/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

      # Session variables
      export REPORTTIME="5"
      export LESS="--mouse"
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
