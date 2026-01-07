#!/usr/bin/env bash
# Copy the output of the last command to clipboard
# Uses prompt detection to find command boundaries

set -euo pipefail

# Capture pane content (without escape sequences for cleaner parsing)
content=$(tmux capture-pane -p -S -10000 2>/dev/null) || {
    echo "Failed to capture pane" >&2
    exit 1
}

if [[ -z "$content" ]]; then
    echo "No pane content" >&2
    exit 1
fi

# Find the last command's output by looking for prompt markers
# The prompt pattern ends with ❯ (possibly followed by git info and another ❯)
# We want content between the second-to-last prompt line and the last prompt line

output=$(echo "$content" | awk '
    # Match prompt lines - they contain ❯ and typically start the line or have the dir name
    /❯ / || /❯$/ {
        # Store this as a potential prompt line number
        prompt_lines[prompt_count++] = NR
    }
    {
        # Store all lines
        lines[NR] = $0
    }
    END {
        if (prompt_count < 2) {
            # Not enough prompts to find output
            exit 1
        }

        # Get the line after the second-to-last prompt (start of last command output)
        start = prompt_lines[prompt_count - 2] + 1

        # Get the line of the last prompt (end of output, exclusive)
        end = prompt_lines[prompt_count - 1] - 1

        # Print lines between prompts (the command output)
        for (i = start; i <= end; i++) {
            print lines[i]
        }
    }
')

if [[ -n "$output" ]]; then
    # Copy to clipboard (macOS, X11, Wayland)
    if command -v pbcopy >/dev/null 2>&1; then
        printf '%s' "$output" | pbcopy
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$output" | xclip -selection clipboard
    elif command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$output" | wl-copy
    else
        echo "No clipboard command found" >&2
        exit 1
    fi
else
    echo "No output found between prompts" >&2
    exit 1
fi
