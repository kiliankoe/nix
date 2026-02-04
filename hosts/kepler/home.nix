_: {
  home-manager.users.kilian = {
    programs.tmux.extraConfig = ''
      set -g status-bg green
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=green
    '';
    programs.starship.settings.hostname.format = "[$hostname ](bold green)";
  };
}
