{
  # programs.sesh's tmux integration asserts on
  # programs.fzf.tmux.enableShellIntegration, even though the binding it
  # generates uses fzf's own `--tmux` flag and needs nothing from the shell
  # integration. Enabling fzf here only satisfies that assertion: the option
  # sets FZF_TMUX=1, which is read exclusively by fzf's shell widgets, and
  # those are off.
  programs.fzf = {
    enable = true;
    tmux.enableShellIntegration = true;
    # atuin owns ctrl-r (initialized by hand in zsh.nix), and fzf's widgets
    # would additionally claim ctrl-t and alt-c.
    enableZshIntegration = false;
  };

  programs.sesh = {
    enable = true;

    # prefix+s, replacing tmux's choose-tree. Merges running sessions with
    # zoxide's frecency list, so most projects need no entry below; declare
    # one only where the name or startup command should be fixed.
    settings = {
      default_session.startup_command = "eza";

      session = [
        {
          name = "nix";
          path = "~/nix";
          startup_command = "hx";
        }
      ];

      # Popup-only utility sessions, not project jump targets
      blacklist = [ "scratch" ];
    };
  };
}
