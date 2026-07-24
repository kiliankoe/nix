# Prints a one-line blame summary for <file> <line>, sized for helix's statusline.
# Called from a helix keybinding; always exits 0 so failures show up as text
# rather than an opaque "command failed" in the editor.

file=$1
line=$2

cd "$(dirname "$file")" || exit 0
name=$(basename "$file")

if ! blame=$(git blame -L "$line,+1" --porcelain -- "$name" 2>&1); then
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

git log -1 --format='%an, %ar · %h %s' "$hash"
