{ config, pkgs, ... }:
{
  # Install custom Oh My Zsh theme from dotfiles
  home.file.".oh-my-zsh/custom/themes/norm-kilian.zsh-theme" = {
    source = ./norm-kilian.zsh-theme;
  };

  home.sessionPath = [
    "$HOME/bin"
    "$HOME/.bun/bin"
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      df = "df -H";
      du = "du -ch";
      lg = "lazygit";
      rsync = "rsync --progress";
      tmp = "cd $TMPDIR";
      tree = "tree -C";
      lf = "/bin/ls -rt | tail -n1";
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      dockerpwd = "docker run --rm -it -v $(PWD):/src";
      zshconfig = "hx $HOME/nix/home/programs/zsh.nix";
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

    oh-my-zsh = {
      enable = true;
      theme = "norm-kilian";
      plugins = [
        "git"
        "z"
      ];
      extraConfig = ''
        ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
        COMPLETION_WAITING_DOTS="true"
        DEFAULT_USER="kilian"
        zstyle ':omz:update' mode reminder
      '';
    };

    # unfortunately zsh.sessionVariables or zsh.localVariables doesn't appear to be working
    initContent = ''
      # Session variables
      export REPORTTIME="5"
      export EDITOR="hx"
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

      # direnv initialization
      if command -v direnv >/dev/null 2>&1; then
        eval "$(direnv hook zsh)"
      fi

      # atuin initialization
      if command -v atuin >/dev/null 2>&1; then
        eval "$(atuin init zsh --disable-up-arrow)"
      fi
    '';

    # Platform-specific zsh opts are in darwin.nix and nixos.nix
  };
}
