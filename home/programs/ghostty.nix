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
      # The shell integration's cursor feature makes zsh switch to a blinking
      # bar at the prompt, overriding cursor-style. Omitted features keep their
      # default, so this only turns off the cursor part.
      shell-integration-features = "no-cursor";
    };
  };
}
