{ pkgs, config, ... }:
{
  programs.tmux = {
    enable = true;
    enableMouse = true;
    extraConfig = ''
      # C-b is definitely *super easy* to reach...
      set-option -g prefix C-a

      set -g default-terminal "screen-256color"
      setw -g aggressive-resize on

      set -g base-index 1
      set -g renumber-windows on

      set -s escape-time 0

      set -g status-bg magenta
      set -g status-fg black

      set -g pane-active-border-style bg=default,fg=magenta
      set -g pane-border-style fg=default

      # rename terminals
      set -g set-titles on

      # more sensible pane splitting, \ doesn't require shift
      bind '\' split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'
      unbind '"'
      unbind %

      # move windows with ctrl shift+arrow
      bind-key S-Left swap-window -t -1 -d
      bind-key S-Right swap-window -t +1 -d

      bind r source-file /etc/tmux.conf \; display-message "Reloaded config..."

      # Remap window navigation to vim bindings
      unbind-key j
      bind-key j select-pane -D
      unbind-key k
      bind-key k select-pane -U
      unbind-key h
      bind-key h select-pane -L
      unbind-key l
      bind-key l select-pane -R

      # Set the window title string
      set-window-option -g automatic-rename off

      # Active/current window styles
      set-window-option -g window-status-current-style "fg=black,bg=white,bold"

      # Format for active window: show directory name for zsh, command name otherwise, and Z if zoomed
      set-window-option -g window-status-current-format " #I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,} "

      # Format for inactive windows: same logic as active
      set-window-option -g window-status-format " #I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,} "

      # Set terminal window title to reflect current window
      set-option -g set-titles-string "#I:#(if [ \"#{pane_current_command}\" = \"zsh\" ]; then basename \"#{pane_current_path}\" 2>/dev/null || echo \"?\"; else echo \"#{pane_current_command}\"; fi)#{?window_zoomed_flag, Z,}"
    '';
  };
}