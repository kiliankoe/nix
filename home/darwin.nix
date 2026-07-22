{
  config,
  lib,
  ...
}:
{
  home.sessionVariables = {
    # macOS uses 'open' for default browser
    BROWSER = "open";
    # some stuff just doesn't play nicely when using a GUI editor as $EDITOR
    # EDITOR = "zed";
    # Ghostty (Homebrew cask) ships its terminfo inside the app bundle where
    # ncurses doesn't look; without this, mosh-server rejects incoming
    # mosh sessions from Ghostty clients (TERM=xterm-ghostty). Home-manager's
    # darwin target sets this with mkDefault (profile + /usr/share/terminfo),
    # so prepend the Ghostty dir while keeping that composition intact.
    TERMINFO_DIRS = "/Applications/Ghostty.app/Contents/Resources/terminfo:${config.home.profileDirectory}/share/terminfo:$TERMINFO_DIRS\${TERMINFO_DIRS:+:}/usr/share/terminfo";
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
