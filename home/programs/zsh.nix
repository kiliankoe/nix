{ config, pkgs, ... }:
{
  # Install custom Oh My Zsh theme from dotfiles
  home.file.".oh-my-zsh/custom/themes/norm-kilian.zsh-theme" = {
    source = ./norm-kilian.zsh-theme;
  };

  home.sessionVariables = {
    REPORTTIME = "5";
    EDITOR = "hx";
    # fixes mouse scrolling in bat's pager output in tmux
    LESS = "--mouse";
  }
  // pkgs.lib.mkIf pkgs.stdenv.isDarwin {
    ICLOUD_DRIVE = "$HOME/Library/Mobile Documents/com~apple~CloudDocs";
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
        # "fzf"
      ];
      extraConfig = ''
        COMPLETION_WAITING_DOTS="true"
        DEFAULT_USER="kilian"
        zstyle ':omz:update' mode reminder
      '';
    };

    initContent = ''
      # Load private dotfiles if they exist
      if [[ -f ~/dev/dotfiles/private ]]; then
        source ~/dev/dotfiles/private
      fi

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

  # Not sure if I'm still using fzf, possibly re-enable later
  # programs.fzf = {
  #   enable = true;
  #   enableZshIntegration = true;
  # };
}
