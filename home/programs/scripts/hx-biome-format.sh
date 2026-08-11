# Runs biome as helix's formatter, applying a house style where the project has no
# opinion. biome's own default is tabs and there is no user-level config to change
# that: --config-path replaces project discovery instead of layering under it, so
# pointing it at a global file would make every project's biome.json invisible.
#
# Passing --indent-style=space unconditionally is equally wrong, because CLI flags
# outrank biome.json, so a project that deliberately picked tabs would be silently
# reformatted. The house style is therefore only supplied when nothing else speaks up:
#
#   biome.json > .editorconfig > house style (here) > biome's built-in defaults
#
# Indentation is all the house style has to say. 2-space width, double quotes and
# always-on semicolons are wanted too, but those are already biome's defaults, so
# spelling them out would only be noise.
#
# helix runs formatters with the document's directory as cwd, which is where biome
# starts its own upward search, so walking up from $PWD resolves the same config
# biome would pick, nearest-first.

# `check --write`, not `format`: sorting imports is an assist action, and `format`
# only ever formats, so with `format` a project that enables organizeImports reports
# the violation and then never fixes it. The linter is switched off for this pass so
# :fmt stays formatting plus assists and never silently applies lint autofixes, which
# would rewrite code (novacloud's useConsistentArrayType turns Array<T> into T[]) on
# what is meant to be a formatting keystroke. Drop --linter-enabled=false to opt into
# safe lint fixes as well, matching what VS Code's source.fixAll does on save.
#
# --write is safe here despite the name: with --stdin-file-path biome writes the
# result to stdout and leaves the file on disk alone.
biome=(biome check --write --linter-enabled=false)

# helix passes the buffer path relative to its own cwd, but runs the formatter in
# the document's directory, so only the last component is meaningful to biome — a
# relative path here would resolve to a doubled one, and biome aborts outright with
# "Found a nested root configuration" if that reaches into a subtree owning its own
# biome.json. Taking the basename here rather than via helix's %sh{} keeps the path
# out of a shell: next.js route dirs like `(main)` are shell syntax and `[lng]` is a
# glob, so a path through either dies before biome ever sees a filename.
name=$(basename "$1")

dir=$PWD
while :; do
  # The project configures biome directly, so stay out of it entirely.
  if [ -e "$dir/biome.json" ] || [ -e "$dir/biome.jsonc" ]; then
    exec "${biome[@]}" --stdin-file-path="$name"
  fi

  # biome reads .editorconfig only when asked, and biome.json would still win over
  # it, so enabling it here cannot override a project's own biome settings. It also
  # covers indentation and nothing else, which is exactly the house style's scope,
  # so there is nothing left to add on top.
  if [ -e "$dir/.editorconfig" ]; then
    exec "${biome[@]}" --use-editorconfig=true --stdin-file-path="$name"
  fi

  [ "$dir" = / ] && break
  dir=$(dirname "$dir")
done

exec "${biome[@]}" --indent-style=space --stdin-file-path="$name"
