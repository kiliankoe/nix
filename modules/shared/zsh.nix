{ pkgs, lib, ... }:
let
  commonAliases = {
    df = "df -H";
    du = "du -ch";
    lg = "lazygit";
    rsync = "rsync --progress";
    tmp = "cd $TMPDIR";
    tree = "tree -C";
    l = "ls -lAhG";
    ls = "ls -G";
    lf = "/bin/ls -rt | tail -n1";
    ".." = "cd ..";
    "..." = "cd ../../";
    "...." = "cd ../../../";
    "....." = "cd ../../../../";
    dockerpwd = "docker run --rm -it -v $(PWD):/src";
    zshreload = "source ~/dev/dotfiles/zshrc";
  };
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;

    shellInit = ''
      # report time a command took if it's longer than n seconds
      REPORTTIME=5

      # general environment
      export EDITOR="vim"
      export PATH="$PATH:$HOME/bin:$HOME/.bun/bin"

      # fixes mouse scrolling in bat's pager output in tmux
      export LESS="--mouse"
    '';

    # Interactive shell setup
    interactiveShellInit = ''
      # Oh My Zsh configuration
      export ZSH=$HOME/.oh-my-zsh
      ZSH_THEME="norm-kilian" # mh and norm are pretty nice
      DEFAULT_USER="kilian"

      plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)
      COMPLETION_WAITING_DOTS="true"

      zstyle ':omz:update' mode reminder

      # Load Oh My Zsh if it exists
      if [[ -f $ZSH/oh-my-zsh.sh ]]; then
        source $ZSH/oh-my-zsh.sh
      fi

      # Load private dotfiles if they exist
      if [[ -f ~/dev/dotfiles/private ]]; then
        source ~/dev/dotfiles/private
      fi

      # Load host-specific secrets
      SECRETS_FILE="$HOME/.config/secrets/env"
      if [[ -f "$SECRETS_FILE" ]]; then
        source "$SECRETS_FILE"
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
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    # macOS-specific options
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableFzfHistory = lib.mkDefault true;
    enableFzfGit = lib.mkDefault true;

    # macOS-specific environment variables
    variables = {
      ICLOUD_DRIVE = "$HOME/Library/Mobile Documents/com~apple~CloudDocs";
    };
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    # NixOS-specific options
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = commonAliases;

    histSize = 20000;
    setOptions = [
      "HIST_EXPIRE_DUPS_FIRST"
      "HIST_IGNORE_DUPS"
      "HIST_IGNORE_SPACE"
      "HIST_SAVE_NO_DUPS"
      "SHARE_HISTORY"
    ];
  };

  # Add shell aliases for macOS too, but through a different mechanism
  # since nix-darwin doesn't have shellAliases option
  environment.shellAliases = lib.mkIf pkgs.stdenv.isDarwin commonAliases;
}
