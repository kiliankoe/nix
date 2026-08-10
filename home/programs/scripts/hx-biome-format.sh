# Runs biome as helix's formatter, defaulting to spaces where the project has no
# opinion. biome's own default is tabs and there is no user-level config to change
# that: --config-path replaces project discovery instead of layering under it, so
# pointing it at a global file would make every project's biome.json invisible.
#
# Passing --indent-style=space unconditionally is equally wrong, because CLI flags
# outrank biome.json, so a project that deliberately picked tabs would be silently
# reformatted. The default is therefore only supplied when nothing else speaks up:
#
#   biome.json > .editorconfig > space (here) > biome's built-in tab
#
# helix runs formatters with the document's directory as cwd, which is where biome
# starts its own upward search, so walking up from $PWD resolves the same config
# biome would pick, nearest-first.

name=$1

dir=$PWD
while :; do
  # The project configures biome directly, so stay out of it entirely.
  if [ -e "$dir/biome.json" ] || [ -e "$dir/biome.jsonc" ]; then
    exec biome format --stdin-file-path="$name"
  fi

  # biome reads .editorconfig only when asked, and biome.json would still win over
  # it, so enabling it here cannot override a project's own biome settings.
  if [ -e "$dir/.editorconfig" ]; then
    exec biome format --use-editorconfig=true --stdin-file-path="$name"
  fi

  [ "$dir" = / ] && break
  dir=$(dirname "$dir")
done

exec biome format --indent-style=space --stdin-file-path="$name"
