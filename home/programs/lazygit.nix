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

      git = {
        # Background fetch has no timeout, so instances left open on repos whose
        # remotes are only reachable via VPN burn CPU spinning until ssh gives up.
        # See https://github.com/jesseduffield/lazygit/issues/4734
        # autoFetch = false;
      };

      services = {
        "code.wabo.run" = "gitlab:code.wabo.run";
      };
    };
  };
}
