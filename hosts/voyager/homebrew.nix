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

    masApps = {
      "AusweisApp" = 948660805;
      "Bluetooth Inspector" = 1509085044;
      "Compressor" = 424390742;
      "CustomSymbols" = 1566662030;
      "Day One" = 1055511498;
      "Final Cut Pro" = 424389933;
      "Gifski" = 1351639930;
      "Logic Pro" = 634148309;
      "RocketSim" = 1504940162;
      "Unfolder" = 1410628659;
      "Yomu" = 562211012;
    };
  };
}
