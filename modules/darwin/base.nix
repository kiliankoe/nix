{ pkgs, ... }:
{
  nix.enable = true;
  nix.settings.experimental-features = "nix-command flakes";

  # Optimize Nix-Store During Rebuilds
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # https://nix-darwin.github.io/nix-darwin/manual/

  system.defaults = {
    # NSGlobalDomain, duh
    NSGlobalDomain = {
      # AppleHighlightColor = "1.000000 0.749020 0.823529 Pink";
      NSTableViewDefaultSizeMode = 1; # small sidebar icons
      NSWindowResizeTime = 0.001;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    # com.apple.dock
    dock = {
      tilesize = 36;
      autohide = true;
      showhidden = true; # make icons of hidden applications translucent
      expose-animation-duration = 0.01;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
    };
    # com.apple.finder
    finder = {
      _FXShowPosixPathInTitle = true;
      FXDefaultSearchScope = "SCcf"; # search current folder by default
      ShowPathbar = true;
      AppleShowAllExtensions = true;
      # DisableAllAnimations = true;
      FXPreferredViewStyle = "clmv"; # column view as default, allowed values: `Nlsv`, `icnv`, `clmv`, `Flwv`
      # WarnOnEmptyTrash = false;
      # OpenWindowForNewRemovableDisk = true;
    };
    # com.apple.screencapture
    screencapture = {
      location = "/Users/kilian/Pictures/Screenshots";
      type = "png";
    };
  };

  # Touch ID for sudo
  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = "kilian";

  home-manager.users.kilian = {
    imports = [
      ../../home/common.nix
      ../../home/darwin.nix
    ];
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
