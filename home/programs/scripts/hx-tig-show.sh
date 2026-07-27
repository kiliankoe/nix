# Opens `tig show <commit>` in a tmux popup for the commit that last touched
# <file>:<line>: full diff, author, and message. From there Enter drills into
# the changed files. Replaces the old one-line statusline blame.
#
# Popup rationale: same as hx-tig-blame — tig is a full-screen TUI and needs its
# own tty, which helix's :sh does not provide.

file=$1
line=$2

# Absolutize here: the popup runs in the tmux pane's cwd, not this script's, so
# the dir has to be passed to display-popup with -d rather than a plain cd.
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd) || exit 0
name=$(basename "$file")

# 2>&1 so a "not tracked"/"not a repo" error surfaces instead of vanishing.
if ! blame=$(git -C "$dir" blame -L "$line,+1" --porcelain -- "$name" 2>&1); then
  printf 'no blame: %s\n' "${blame%%$'\n'*}"
  exit 0
fi

hash=${blame%% *}
case "$hash" in
  0000000*)
    printf 'Not committed yet\n'
    exit 0
    ;;
esac

if [ -z "${TMUX:-}" ]; then
  printf 'tig show needs tmux (helix has no tty for a full-screen TUI)\n'
  exit 0
fi

tmux display-popup -E -d "$dir" -w 90% -h 90% -T "commit ${hash:0:9} (${name}:${line})" \
  "tig show ${hash}"
