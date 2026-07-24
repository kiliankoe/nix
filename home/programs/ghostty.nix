{
  programs.ghostty = {
    enable = true;
    # Ghostty is installed as a Homebrew cask (modules/darwin/homebrew.nix);
    # nixpkgs' ghostty doesn't build on darwin, so manage only the config here.
    package = null;

    # Written to ~/.config/ghostty/config, which Ghostty reads on macOS as well
    # as the ~/Library/Application Support/com.mitchellh.ghostty/config path.
    settings = {
      font-size = 10;
      window-decoration = false;
    };
  };
}
