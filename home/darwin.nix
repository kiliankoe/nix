{
  lib,
  ...
}:
{
  imports = [
    ./programs/zed.nix
  ];

  home.sessionVariables = {
    # macOS uses 'open' for default browser
    BROWSER = "open";
    # some stuff just doesn't play nicely when using a GUI editor as $EDITOR
    # EDITOR = "zed";
  };

  home.homeDirectory = lib.mkForce "/Users/kilian";

  programs.zsh = {
    initContent = ''
      alias brewout="brew outdated"
      alias brewup="brew upgrade && brew cleanup"
      # BSD ls flags
      alias ls='ls -G'
      alias l='ls -lAhG'

      # Homebrew
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';
  };
}
