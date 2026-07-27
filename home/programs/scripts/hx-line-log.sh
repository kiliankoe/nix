# Opens the full history of one line (<file> <line>) in a tmux popup: every
# commit that touched it, newest first, rendered with delta. Complements the
# Space B blame, which only shows the single most recent commit.
#
# Needs tmux for the interactive scroll — helix's :sh captures output instead of
# giving a real pager, so a popup is the only way to get less inside the editor.

file=$1
line=$2

# Absolutize here: the popup runs in the tmux pane's cwd, not this script's, so
# the dir has to be passed to display-popup with -d rather than a plain cd.
dir=$(cd "$(dirname "$file")" 2>/dev/null && pwd) || exit 0
name=$(basename "$file")

if [ -z "${TMUX:-}" ]; then
  printf 'line history needs tmux (helix has no interactive pager)\n'
  exit 0
fi

# git/delta/less resolve from the interactive PATH inside the popup, same as
# running the pipe by hand. 2>&1 so a "not tracked"/"not a repo" error lands in
# the pager instead of vanishing; delta passes non-diff lines through as text.
tmux display-popup -E -d "$dir" -w 90% -h 90% -T "history of ${name}:${line}" \
  "git log -L ${line},+1:'${name}' 2>&1 | delta --paging=never | less -R"
