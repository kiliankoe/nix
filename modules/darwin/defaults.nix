{ ... }:
{
  # https://nix-darwin.github.io/nix-darwin/manual/
  # https://mynixos.com/nix-darwin/options
  # https://macos-defaults.com/

  system.defaults = {
    NSGlobalDomain = {
      # Use small sidebar icons in lists and outlines
      NSTableViewDefaultSizeMode = 1;
      # Disable smart quotes (annoying when typing code)
      NSAutomaticQuoteSubstitutionEnabled = false;
      # Disable smart dashes (annoying when typing code)
      NSAutomaticDashSubstitutionEnabled = false;
      # Disable auto-correct
      NSAutomaticSpellingCorrectionEnabled = false;
      # Enable window dragging when holding ctrl+cmd
      NSWindowShouldDragOnGesture = true;
    };

    # com.apple.dock
    dock = {
      # Automatically hide and show the Dock
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.0;
      # Change minimize/maximize window effect to scale
      mineffect = "scale";
    };

    # com.apple.finder
    finder = {
      # Show file extensions in Finder
      AppleShowAllExtensions = true;
      # When performing a search, search the current folder by default
      FXDefaultSearchScope = "SCcf";
      # Show path bar
      ShowPathbar = true;
      # Use column view as default (icnv=Icon, Nlsv=List, clmv=Column, Flwv=Gallery)
      FXPreferredViewStyle = "clmv";
    };

    # com.apple.screencapture
    screencapture = {
      # Save screenshots to custom directory
      location = "/Users/kilian/Pictures/Screenshots";
      # Save screenshots in PNG format (current: png)
      type = "png";
    };

    # com.apple.AppleMultitouchTrackpad
    trackpad = {
      # Enable tap to click for this user and for the login screen
      Clicking = true;
      # Enable three finger drag
      TrackpadThreeFingerDrag = true;
    };

    # Custom user preferences for settings not directly supported by nix-darwin
    CustomUserPreferences = {
      NSGlobalDomain = {
        AppleAccentColor = "6"; # Pink
        # Disable mouse acceleration
        com.apple.mouse.linear = true;
      };

      # Disable input source indicator at cursor
      kCFPreferencesAnyApplication = {
        TSMLanguageIndicatorEnabled = 0;
      };

      "com.apple.WindowManager" = {
        EnabledTiledWindowMargins = false;
      };

      # Automatically quit printer app once the print jobs complete
      "com.apple.print.PrintingPrefs"."Quit When Finished" = true;

      "com.apple.screensaver" = {
        # Require password immediately after sleep or screen saver begins
        askForPassword = 1;
        askForPasswordDelay = 0;
      };

      # Accessibility settings
      # Could not write domain com.apple.universalaccess; exiting
      # "com.apple.universalaccess" = {
      #   # Use scroll gesture with the Ctrl (^) modifier key to zoom
      #   closeViewScrollWheelToggle = true;
      # };

      # Avoid creating .DS_Store files on network volumes
      "com.apple.desktopservices".DSDontWriteNetworkStores = true;

      "com.apple.frameworks.diskimages" = {
        # Automatically open a new Finder window when a read-only volume is mounted
        auto-open-ro-root = true;
        # Automatically open a new Finder window when a read-write volume is mounted
        auto-open-rw-root = true;
      };

      # defaults[30575:250868958] Could not write domain /Users/kilian/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari; exiting
      # "com.apple.Safari" = {
      #   # Privacy: don't send search queries to Apple
      #   UniversalSearchEnabled = false;
      #   SuppressSearchSuggestions = true;
      #   # Show the full URL in the address bar (note: this still hides the scheme)
      #   ShowFullURLInSmartSearchField = true;
      #   # Set Safari's home page to `about:blank` for faster loading
      #   HomePage = "about:blank";
      #   # Prevent Safari from opening 'safe' files automatically after downloading
      #   AutoOpenSafeDownloads = false;
      #   # Enable Safari's debug menu
      #   IncludeInternalDebugMenu = true;
      #   # Make Safari's search banners default to Contains instead of Starts With
      #   FindOnPageMatchesWordStartsOnly = false;
      #   # Enable the Develop menu and the Web Inspector in Safari
      #   IncludeDevelopMenu = true;
      #   WebKitDeveloperExtrasEnabledPreferenceKey = true;
      #   "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" = true;
      # };

      "com.apple.TextEdit" = {
        # Use plain text mode for new TextEdit documents
        RichText = 0;
        # Open and save files as UTF-8 in TextEdit
        PlainTextEncoding = 4;
        PlainTextEncodingForWrite = 4;
      };

      "com.apple.messageshelper.MessageController".SOInputLineSettings = {
        # Disable smart quotes as it's annoying for messages that contain code
        automaticQuoteSubstitutionEnabled = false;
        # Disable continuous spell checking
        continuousSpellCheckingEnabled = false;
      };

      "com.apple.dt.Xcode" = {
        DVTTextEditorTrimWhitespaceOnlyLines = 1;
      };
    };
  };
}
