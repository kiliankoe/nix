_: {
  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
      # Whether to enable Homebrew to auto-update itself and all formulae during nix-darwin system activation.
      autoUpdate = false;
      # Whether to enable Homebrew to upgrade outdated formulae and Mac App Store apps during nix-darwin system activation.
      upgrade = false;
    };
    taps = [
      "Arthur-Ficial/tap"
      "kiliankoe/formulae"
    ];
    brews = [
      "apfel"
      "gh"
      "mas"
      "mole"
      "nono"
      "swift-outdated"
    ];
    casks = [
      "1password"
      "affinity"
      "anki"
      "arq"
      "audacity"
      "balenaetcher"
      "bambu-studio"
      "beeper"
      "bettermouse"
      "blender"
      "claude"
      "coconutbattery"
      "conductor"
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
      "gimp"
      "google-chrome"
      "godot"
      "gpg-suite"
      "hex-fiend"
      "iina"
      "imageoptim"
      "inkscape"
      "istat-menus"
      "jordanbaird-ice"
      "karabiner-elements"
      "kicad"
      "lightburn"
      "macwhisper"
      "monitorcontrol"
      "mountain-duck"
      "obsidian"
      "ogdesign-eagle"
      "ollama-app"
      "openscad@snapshot"
      "orbstack"
      "pictogram"
      "proxyman"
      "raspberry-pi-imager"
      "raycast"
      "sf-symbols"
      "sloth"
      "soulver"
      "steam"
      "studiolinkstandalone"
      "sublime-text"
      "suspicious-package"
      "tableplus"
      "tailscale-app"
      "the-unarchiver"
      "todoist-app"
      "utm"
      "visual-studio-code"
      "xcodes-app"
      "xscreensaver"
      "yaak"
      "zed"
      "zen"
    ];

    masApps = {
      "Bakery" = 1575220747;
      "Deliveries" = 290986013;
      "Developer" = 640199958;
      "Home Assistant" = 1099568401; # is in brew, but more up to date in mas
      "Keynote" = 409183694;
      "Lungo" = 1263070803;
      "Magnet" = 441258766;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Shareful" = 1522267256;
      "SomaFM" = 449155338;
      "Speediness" = 1596706466;
      "Stempel" = 1638437641;
      "StopTheMadness" = 1376402589;
      "TestFlight" = 899247664;
      "WireGuard" = 1451685025;
      "Yomu" = 562211012;
    };
  };
}
