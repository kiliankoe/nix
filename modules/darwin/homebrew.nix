{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    # onActivation = {
    #   autoUpdate = true;
    # };
    taps = [
      "kiliankoe/formulae"
    ];
    brews = [
      "gh"
      "swift-outdated"
      "mas"
    ];
    casks = [
      "1password"
      "anki"
      "balenaetcher"
      "bambu-studio"
      "beeper"
      "blender"
      "chatgpt"
      "claude"
      "coconutbattery"
      "crossover"
      "cyberduck"
      "daisydisk"
      "devcleaner"
      "discord"
      "element"
      "fantastical"
      "fastmail"
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
      "netnewswire"
      "notion"
      "obsidian"
      "ogdesign-eagle"
      "ollama-app"
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
      "the-unarchiver"
      "todoist-app"
      "utm"
      "visual-studio-code"
      "windows-app"
      "xcodes-app"
      "yaak"
      "zed"
      "zen"
    ];

    masApps = {
      "Bakery" = 1575220747;
      "Developer" = 640199958;
      "Home Assistant" = 1099568401; # is in brew, but more up to date in mas
      "Keynote" = 409183694;
      "Lungo" = 1263070803;
      "Magnet" = 441258766;
      "Navigator" = 1590354537;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Reeder" = 1529448980;
      "Shareful" = 1522267256;
      "SomaFM" = 449155338;
      "Speediness" = 1596706466;
      "Stempel" = 1638437641;
      "StopTheMadness" = 1376402589;
      "TestFlight" = 899247664;
      "WireGuard" = 1451685025;
    };
  };
}
