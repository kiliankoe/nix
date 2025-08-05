{ pkgs, ... }:
{
  imports = [
    ../../modules/darwin/base.nix
    ../../modules/darwin/shared-packages.nix
    # ../../modules/darwin/homebrew.nix
    ../../modules/shared/base.nix
    ../../modules/shared/tmux.nix
    ../../modules/shared/zsh.nix
    ./packages.nix
  ];

  # homebrew = {
  #   brews = [
  #     "wandelbotsgmbh/wandelbots/nova"
  #   ];

  #   taps = [
  #     "wandelbotsgmbh/wandelbots"
  #   ];

  #   casks = [
  #     "1password"
  #     "anki"
  #     "anytype"
  #     "autodesk-fusion"
  #     # "autodesk-fusion360" # Deprecated, use "autodesk-fusion"
  #     "balenaetcher"
  #     "bambu-studio"
  #     "blender"
  #     "chatgpt"
  #     "crossover"
  #     "cursor"
  #     "cyberduck"
  #     "discord"
  #     "docker"
  #     "docker-desktop"
  #     "element"
  #     "fantastical"
  #     "figma"
  #     "firefox"
  #     "font-comic-mono"
  #     "font-jetbrains-mono"
  #     "font-monaspace"
  #     "font-open-sans"
  #     "fork"
  #     "freecad"
  #     "ghostty"
  #     "godot"
  #     "google-chrome"
  #     "hex-fiend"
  #     "iina"
  #     "imageoptim"
  #     "istat-menus"
  #     "jetbrains-toolbox"
  #     "jordanbaird-ice"
  #     "keycastr"
  #     "microsoft-auto-update"
  #     "microsoft-outlook"
  #     "monitorcontrol"
  #     "notion"
  #     "openscad"
  #     "orbstack"
  #     "pictogram"
  #     "proxyman"
  #     "rapidapi"
  #     "raspberry-pi-imager"
  #     "raycast"
  #     "sf-symbols"
  #     "slack"
  #     "soulver"
  #     "steam"
  #     "sublime-text"
  #     "suspicious-package"
  #     "tableplus"
  #     # "todoist" # Deprecated, use "todoist-app"
  #     "todoist-app"
  #     "utm"
  #     "visual-studio-code"
  #     "yaak"
  #     "zed"
  #     # Which one of these is the installed one?
  #     "zen"
  #     "zen-browser"
  #     "zoo-design-studio"
  #   ];
  # };

  nixpkgs.hostPlatform = "aarch64-darwin";
}
