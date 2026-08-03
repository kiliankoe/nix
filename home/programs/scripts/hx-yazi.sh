# Opens yazi in a tmux popup with <file> hovered, so rename/move/delete/create
# have a home. Helix only ships `:mv` (rename the current buffer's file); there
# is no delete or copy command, and its file explorer (space e) only navigates.
#
# Popup rationale: same as hx-tig-blame — yazi is a full-screen TUI and needs its
# own tty, which helix's :sh does not provide.
#
# Opening a file inside the popup spawns a nested helix via $EDITOR. That works,
# but it's a separate session from the one you came from; use space f instead.

file=$1

# Absolutize here: the popup runs in the tmux pane's cwd, not this script's, so
# the dir has to be passed to display-popup with -d rather than a plain cd.
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd) || dir=$PWD
name=$(basename "$file")

# A scratch buffer's name ("[scratch]") is not a path, so hover nothing and just
# open the directory helix was started in.
if [ -e "$dir/$name" ]; then
  target=$name
else
  target=.
fi

if [ -z "${TMUX:-}" ]; then
  printf 'yazi needs tmux (helix has no tty for a full-screen TUI)\n'
  exit 0
fi

# yazi resolves from the interactive PATH inside the popup (it's in systemPackages).
tmux display-popup -E -d "$dir" -w 90% -h 90% -T "files: ${dir}" \
  "yazi '${target}'"
