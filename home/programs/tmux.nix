{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    package = pkgs.tmux;
    sensibleOnTop = true;
    mouse = true;
    prefix = "C-a";
    baseIndex = 1;
    clock24 = true;

    # These are taken care of by tmux-sensible, verify though before removing.
    # escapeTime = 0;
    # terminal = "screen-256color";
    # aggressiveResize = true;
    # historyLimit = 10000;
    # keyMode = "emacs"; # Default, but explicit

    extraConfig = ''
      # Explicitly set and bind the prefix for nested sessions,
      # only using `prefix` above doesn't suffice unfortunately
      unbind C-b
      set -g prefix C-a
      bind C-a send-prefix

      # Renumber windows when one is closed
      set -g renumber-windows on

      # More sensible pane splitting, \ stands for | but doesn't require shift
      bind '\' split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'
      unbind '"'
      unbind %

      # Move windows with ctrl shift+arrow
      bind-key S-Left swap-window -t -1 -d
      bind-key S-Right swap-window -t +1 -d

      # Vim-style pane navigation
      unbind-key j
      bind-key j select-pane -D
      unbind-key k
      bind-key k select-pane -U
      unbind-key h
      bind-key h select-pane -L
      unbind-key l
      bind-key l select-pane -R

      # Set title and disable automatic renaming
      set -g set-titles on
      set-window-option -g automatic-rename off

      # Styling
      set -g status-bg magenta
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=magenta
      set -g pane-border-style fg=default
      set-window-option -g window-status-current-style "fg=black,bg=white,bold"

      # Format for active window: show directory name for zsh, command name otherwise, and Z if zoomed
      set-window-option -g window-status-current-format " #I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,} "

      # Format for inactive windows: same logic as active
      set-window-option -g window-status-format " #I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,} "

      # Set terminal window title to reflect current window
      set-option -g set-titles-string "#I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,}"

      # Reload config on prefix-r - is this even still necessary with nix/home-manager?
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Reloaded config..."
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
    ];
  };
}
