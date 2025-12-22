{ pkgs, ... }:
{
  homebrew = {
    taps = [ ];

    brews = [ ];

    casks = [
      "audacity"
      "calibre"
      "deluge"
      "forecast"
      "handbrake-app"
      "minecraft"
      "mullvad-vpn"
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
      "CustomSymbols" = 1566662030;
      "Day One" = 1055511498;
      "Gifski" = 1351639930;
      "Logic Pro" = 634148309;
      "Unfolder" = 1410628659;
    };
  };
}
