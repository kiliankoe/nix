{ pkgs, ... }:
{
  homebrew = {
    taps = [ ];

    brews = [ ];

    casks = [
      "audacity"
      "calibre"
      "deluge"
      "fmail3"
      "forecast"
      "handbrake-app"
      "minecraft"
      "nault"
      "sketch"
      "tor-browser"
      "transmission"
      "ungoogled-chromium"
      # "wacom-tablet" # install when necessary
      "zoo-design-studio"
    ];
  };
}
