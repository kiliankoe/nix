{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
    };
    taps = [
      "homebrew/bundle"
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/core"
      "kiliankoe/formulae"
    ];
    brews = [
      "gh"
      "swift-outdated"
      "codex"
    ];
    casks = [
      "1password"
      "anki"
      "balenaetcher"
      "bambu-studio"
      "blender"
      "chatgpt"
      "claude"
      "coconutbattery"
      "crossover"
      "cyberduck"
      "discord"
      "element"
      "fantastical"
      "firefox"
      "font-comic-mono"
      "font-jetbrains-mono"
      "font-monaspace"
      "font-sf-pro"
      "fork"
      "freecad"
      "ghostty"
      "godot"
      "gpg-suite"
      "hex-fiend"
      "iina"
      "imageoptim"
      "istat-menus"
      "jordanbaird-ice"
      "macdependency"
      "monitorcontrol"
      "notion"
      "ollama"
      "openscad"
      "orbstack"
      "pictogram"
      "proxyman"
      "raspberry-pi-imager"
      "raycast"
      "sf-symbols"
      "sloth"
      "soulver"
      "steam"
      "sublime-text"
      "suspicious-package"
      "tableplus"
      "tailscale-app"
      "todoist-app"
      "utm"
      "visual-studio-code"
      "windows-app"
      "xcodes-app"
      "yaak"
      "zed"
      "zen"
    ];
  };
}
