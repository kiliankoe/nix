{ pkgs, ... }:
let
  inherit (pkgs.tmuxPlugins) tmux-fzf;
  tmux-fzf-scripts = "${tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts";
  # Window title: directory, with |command appended when non-shell and Z when
  # zoomed. A manual rename (prefix+,) turns automatic-rename off for that
  # window, in which case the manual name (#W) is shown instead.
  # Note: boolean options expand to 1/0 in formats, so use the plain #{?} test
  windowTitle = "#{?automatic-rename,#{b:pane_current_path}#{?#{==:#{pane_current_command},zsh},,|#{pane_current_command}},#W}#{?window_zoomed_flag, Z,}";
in
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

      # Set terminal titles. automatic-rename stays on so the auto format below
      # is used by default; a manual rename (prefix+,) turns it off for that
      # window and the manual name wins.
      set -g set-titles on
      set-window-option -g automatic-rename on

      # Renaming a window to an empty name (prefix+, then clear) goes back to
      # the automatic title (stock tmux would keep an empty manual name)
      set-hook -g after-rename-window 'if -F "#{==:#{window_name},}" "setw automatic-rename on"'

      # Styling
      set -g status-bg magenta
      set -g status-fg black
      set -g pane-active-border-style bg=default,fg=magenta
      set -g pane-border-style fg=default
      set-window-option -g window-status-current-style "fg=black,bg=white,bold"

      # Move windows with ctrl shift+arrow
      bind-key -n C-S-Left swap-window -t -1\; select-window -t -1
      bind-key -n C-S-Right swap-window -t +1\; select-window -t +1

      # Format for active window: directory|command (or the manual name), see windowTitle above
      set-window-option -g window-status-current-format " #I:${windowTitle} "

      # Format for inactive windows: same logic as active
      set-window-option -g window-status-format " #I:${windowTitle} "

      # Set terminal window title to reflect current window
      set-option -g set-titles-string "#I:${windowTitle}"

      # Reload config on prefix-r - is this even still necessary with nix/home-manager?
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "Reloaded config..."

      # Override sensible plugin's reattach-to-user-namespace wrapper (unnecessary since tmux 2.6+)
      set -g default-command "$SHELL"

      # Enable OSC 52 clipboard (works through SSH/nested sessions)
      set -g set-clipboard on

      # Allow escape sequences to pass through to the outer terminal (needed for nested tmux)
      set -g allow-passthrough on

      # Send extended key sequences so apps can distinguish e.g. C-i from Tab, S-Enter, etc.
      set -g extended-keys on
      set -s extended-keys-format csi-u

      # Copy last command's output to clipboard (uses OSC 133 markers from zsh)
      bind y run-shell "~/.local/bin/tmux-copy-last-output" \; display-message "Last output copied"

      # Quick window switcher with fzf (prefix + f)
      bind-key f run-shell -b "${tmux-fzf-scripts}/window.sh switch"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      resurrect
      continuum
      {
        # prefix + space
        plugin = tmux-thumbs;
        extraConfig = ''
          # Replaces the default next-layout binding
          set -g @thumbs-key space
          # set-buffer -w puts the pick in the system clipboard (via OSC 52,
          # so it also works over SSH), not just in the tmux buffer. Don't use
          # @thumbs-osc52 for this: it writes the escape sequence to stdout of
          # the run-shell job driving thumbs, and tmux shows any such output in
          # view mode instead of forwarding it, which blanks the pane.
          set -g @thumbs-command 'tmux set-buffer -w -- "{}" && tmux display-message "Copied {}"'
          set -g @thumbs-upcase-command 'tmux set-buffer -w -- "{}" && tmux paste-buffer && tmux display-message "Copied {}"'
        '';
      }
      {
        plugin = tmux-fzf;
        extraConfig = ''
          TMUX_FZF_LAUNCH_KEY="F"
          TMUX_FZF_OPTIONS="-p -w 62% -h 38%"
          TMUX_FZF_WINDOW_FORMAT="#{window_name} | #{pane_current_command} | #{pane_current_path} (#{window_panes} panes)"
        '';
      }
    ];
  };
}
