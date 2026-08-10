{
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.tmuxPlugins) tmux-fzf;

  tmux-window-search = pkgs.writeShellApplication {
    name = "tmux-window-search";
    runtimeInputs = [
      pkgs.fzf
      pkgs.gnugrep
      pkgs.tmux
    ];
    text = builtins.readFile ./scripts/tmux-window-search.sh;
  };

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

    # tmux's own terminfo entry rather than screen's. sensible would otherwise
    # set screen-256color, which has no italics, reports standout as italic,
    # advertises ^H for backspace tmux sends DEL, and lacks E3 (drop scrollback).
    # sensible only upgrades the value when it's exactly home-manager's "screen"
    # default, so setting it here takes precedence.
    # This however needs ncurses 6.x wherever TERM is exported to. Fine on my
    # machines, but maybe a slim container would need TERM=xterm-256color.
    terminal = "tmux-256color";

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

      # Swap panes with Shift+H/J/K/L. L displaces stock tmux's
      # switch-client -l, which moved to prefix+Tab below.
      bind-key H swap-pane -s '{left-of}'
      bind-key J swap-pane -s '{down-of}'
      bind-key K swap-pane -s '{up-of}'
      bind-key L swap-pane -s '{right-of}'

      # Prefix-less pane navigation and zoom. Root-table bindings take these
      # keys away from every app in every pane, which is affordable here:
      # helix leaves Alt+hjkl/z unbound and in zsh only M-h (run-help) and
      # M-l (down-case-word) are shadowed. ghostty has macos-option-as-alt
      # = "right", so right Option sends Alt and left Option still types
      # umlauts. Caveat: ssh'd from local tmux into a remote one, the outer
      # server consumes these before the inner sees them (as with C-S-arrows).
      bind-key -n M-h select-pane -L
      bind-key -n M-j select-pane -D
      bind-key -n M-k select-pane -U
      bind-key -n M-l select-pane -R
      bind-key -n M-z resize-pane -Z

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

      # Allow select -> copy over mosh:
      # Name the clipboard selection explicitly. tmux leaves the selection
      # field empty when copying (OSC 52;;<data>), which every real terminal
      # accepts, but mosh's emulator only recognizes the literal "52;c;" form
      # and silently drops anything else — so copies never reach the local
      # clipboard over mosh. %p1 stays in the format because tparm refuses to
      # expand a capability that skips a parameter; it expands to nothing.
      set -as terminal-overrides ',*:Ms=\E]52;c%p1%s;%p2%s\007'

      # Allow escape sequences to pass through to the outer terminal (needed for nested tmux)
      set -g allow-passthrough on

      # Send extended key sequences so apps can distinguish e.g. C-i from Tab, S-Enter, etc.
      set -g extended-keys on
      set -s extended-keys-format csi-u

      # Clear the pane and its scrollback. -R resets the pane's terminal state
      # C-l makes the shell redraw its prompt, and clear-history then discards
      # everything. The order matters.
      bind C-k send-keys -R \; send-keys C-l \; clear-history

      # Copy last command's output to clipboard (detects the starship prompt glyph)
      bind y run-shell "~/.local/bin/tmux-copy-last-output" \; display-message "Last output copied"

      # Quick window switcher (prefix + f): fuzzy-matches window labels and,
      # additionally, the text currently visible in each window's panes
      bind-key f display-popup -E -w 80% -h 60% "${lib.getExe tmux-window-search}"

      # Session-per-project, see home/programs/sesh.nix for the picker itself.
      # Killing a session jumps to another one instead of detaching to a bare
      # shell.
      set -g detach-on-destroy off
      # Toggle to the previously used session. Stock tmux puts this on
      # prefix+L, which swap-pane took above.
      bind-key Tab switch-client -l

      # lazygit over whatever pane was active, on its repo. Fresh process per
      # invocation (which is what you want for lazygit), q quits, no layout
      # disturbance.
      bind-key g display-popup -E -w 95% -h 95% -d '#{pane_current_path}' lazygit

      # Scratchpad toggle. tmux doesn't set $TMUX inside a popup, so the
      # nested attach isn't refused: this is a second client of the same
      # server attached to a `scratch` session (-A = attach-or-create).
      # Pressing the key from inside detaches that client and closes the
      # popup while the session keeps running, so half-typed commands
      # survive. Being a real session, resurrect snapshots it too — and it's
      # blacklisted in sesh.nix so it stays out of the session picker.
      bind-key S if -F '#{==:#{session_name},scratch}' { detach } { display-popup -E -w 80% -h 75% "tmux new -A -s scratch" }
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      {
        plugin = resurrect;
        extraConfig = ''
          # Restore visible scrollback along with the layout
          set -g @resurrect-capture-pane-contents 'on'
          # Beyond resurrect's default whitelist (vim, less, top, ...). Tilde
          # relaxes matching to a substring.
          set -g @resurrect-processes '"~hx" "~lazygit" "~btop"'
        '';
      }
      {
        # Must stay after resurrect, continuum drives its save/restore scripts
        plugin = continuum;
        extraConfig = ''
          # Restore the last snapshot when the tmux server starts.
          set -g @continuum-restore 'on'
        '';
      }
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
