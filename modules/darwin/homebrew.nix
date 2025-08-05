{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/core"
      "kiliankoe/formulae"
      "oven-sh/bun"
    ];
    brews = [
      "gh"
      "swift-outdated"
    ];
  };
}