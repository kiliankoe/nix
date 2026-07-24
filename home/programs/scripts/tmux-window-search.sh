# Window switcher (prefix + f) that matches both the window label and the text
# currently visible in that window's panes.
#
# fzf can only match against what it displays, so the pane text can't be
# smuggled into a hidden field (--with-nth narrows matching too). Instead fzf's
# own matcher is disabled and this script re-runs itself on every keystroke via
# `reload`: labels are matched fuzzily by `fzf --filter`, pane text by a literal
# case-insensitive grep, which is what you actually want for on-screen text.

label_format='#{window_id}	#{session_name}:#{window_index}: #{window_name} | #{pane_current_command} | #{pane_current_path} (#{window_panes} panes)'

# Panes are captured once at startup, not per keystroke: the snapshot is what
# was on screen when the picker opened, and greps stay local to a temp dir.
snapshot() {
  mkdir -p "$cache/panes"
  tmux list-windows -a -F "$label_format" >"$cache/windows"
  while read -r window pane; do
    tmux capture-pane -p -t "$pane" >>"$cache/panes/$window"
  done < <(tmux list-panes -a -F '#{window_id} #{pane_id}')
}

filter() {
  local query=$1

  if [[ -z $query ]]; then
    cat "$cache/windows"
    return
  fi

  local label_hits
  label_hits=$(fzf --filter="$query" --delimiter=$'\t' --nth=2.. <"$cache/windows" || true)
  if [[ -n $label_hits ]]; then
    printf '%s\n' "$label_hits"
  fi

  local -A listed=()
  local window label hit
  while IFS=$'\t' read -r window label; do
    if [[ -n $window ]]; then
      listed[$window]=1
    fi
  done <<<"$label_hits"

  # Windows the label search missed, but whose visible text contains the query
  while IFS=$'\t' read -r window label; do
    if [[ -n ${listed[$window]:-} ]]; then
      continue
    fi
    hit=$(grep -i -m1 -F -- "$query" "$cache/panes/$window" 2>/dev/null) || continue
    hit=$(printf '%s' "$hit" | tr -s '[:space:]' ' ' | sed 's/^ //' | cut -c1-60)
    printf '%s\t%s  » %s\n' "$window" "$label" "$hit"
  done <"$cache/windows"
}

if [[ ${1:-} == filter ]]; then
  cache=$TMUX_WINDOW_SEARCH_CACHE
  filter "${2:-}"
  exit 0
fi

cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
export TMUX_WINDOW_SEARCH_CACHE=$cache
snapshot

self=${BASH_SOURCE[0]}
target=$(
  fzf --disabled \
    --delimiter=$'\t' --with-nth=2.. --accept-nth=1 \
    --prompt='window> ' --info=inline --no-sort \
    --preview="grep -i -F --color=always -C2 -- {q} '$cache'/panes/{1} 2>/dev/null || cat '$cache'/panes/{1}" \
    --preview-window=right:55%:wrap \
    --bind="start:reload('$self' filter {q})" \
    --bind="change:reload('$self' filter {q})+first"
) || exit 0

[[ -n $target ]] || exit 0
tmux switch-client -t "$(tmux display-message -p -t "$target" '#{session_id}')"
tmux select-window -t "$target"
