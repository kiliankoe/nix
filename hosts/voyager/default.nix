{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/shared-packages.nix
    ../../modules/shared/base.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ../../packages/voyager-packages.nix
  ];

  # Voyager-specific Homebrew casks
  homebrew.casks = [
    "0-ad"
    "anki"
    "audacity"
    "balenaetcher"
    "bambu-studio"
    "blender"
    "calibre"
    "chatgpt"
    "coconutbattery"
    "crossover"
    "cyberduck"
    "deluge"
    "element"
    "fantastical"
    "firefox"
    "fmail2"
    "font-jetbrains-mono"
    "font-monaspace"
    "font-sf-pro"
    "forecast"
    "fork"
    "freecad"
    "ghostty"
    "godot"
    "gpg-suite"
    "handbrake-app"
    "hex-fiend"
    "homerow"
    "iina"
    "imageoptim"
    "istat-menus"
    "macdependency"
    "minecraft"
    "monitorcontrol"
    "nault"
    "notion"
    "openscad"
    "orbstack"
    "pictogram"
    "proxyman"
    "raspberry-pi-imager"
    "raycast"
    "sf-symbols"
    "signal"
    "sketch"
    "sloth"
    "steam"
    "sublime-text"
    "suspicious-package"
    "tableplus"
    "tailscale-app"
    "telegram"
    "todoist-app"
    "transmission"
    "ungoogled-chromium"
    "utm"
    "visual-studio-code"
    "windows-app"
    "wireshark-app"
    "xcodes-app"
    "yaak"
    "zed"
    "zen"
    "zoo-design-studio"
  ];

  # Voyager-specific system configuration
  system.primaryUser = "kilian";
  nixpkgs.hostPlatform = "aarch64-darwin";
}
