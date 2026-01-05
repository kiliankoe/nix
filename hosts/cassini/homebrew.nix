{ pkgs, ... }:
{
  homebrew = {
    taps = [
      "wandelbotsgmbh/wandelbots"
    ];

    brews = [
      "wandelbotsgmbh/wandelbots/nova"
    ];

    casks = [
      "docker-desktop"
      "figma"
      "font-open-sans"
      "google-chrome"
      "microsoft-auto-update"
      "microsoft-outlook"
      "microsoft-teams"
      "openvpn-connect"
      "slack"
      "ultrastardeluxe"
      "windows-app"
    ];
  };
}
