_: {
  programs.lazygit = {
    enable = true;

    # This also defines the `lg` wrapper, no need for an extra alias.
    enableZshIntegration = true;

    settings = {
      gui = {
        # Use custom icons for files and PR indicators
        nerdFontsVersion = "3";
      };

      services = {
        "code.wabo.run" = "gitlab:code.wabo.run";
      };
    };
  };
}
