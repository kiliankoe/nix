# Opens `tig blame` for <file> in a tmux popup, cursor on <line>. From there `,`
# walks to the parent commit's blame, so you can trace a line back through its
# whole history. Complements Space B, which only echoes the last commit.
#
# The popup is what makes this work: tig is a full-screen TUI that needs a real
# terminal, but helix's :sh/:! capture output with no tty (running `:! tig`
# corrupts the screen). display-popup gives tig its own pty, isolated from helix.

file=$1
line=$2

# Absolutize here: the popup runs in the tmux pane's cwd, not this script's, so
# the dir has to be passed to display-popup with -d rather than a plain cd.
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd) || exit 0
name=$(basename "$file")

if [ -z "${TMUX:-}" ]; then
  printf 'tig blame needs tmux (helix has no tty for a full-screen TUI)\n'
  exit 0
fi

# tig resolves from the interactive PATH inside the popup (it's in systemPackages).
tmux display-popup -E -d "$dir" -w 90% -h 90% -T "blame ${name}:${line}" \
  "tig blame +${line} '${name}'"
