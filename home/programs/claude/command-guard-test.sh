# Runs command-guard-tests.txt against command-guard.jq. Invoked from the
# guard's checkPhase, so a rule that breaks a case fails the build rather than
# surfacing as a hook that quietly stopped prompting.
#
# Usage: command-guard-test.sh <program.jq> <tests.txt>

program=$1
tests=$2
failures=0

while IFS= read -r line; do
  case $line in
    '' | '#'*) continue ;;
  esac

  expect=${line%%	*}
  command=${line#*	}

  decision=$(jq -n --arg c "$command" '{tool_input: {command: $c}}' | jq -c -f "$program")

  case $expect in
    ask)
      if [ -z "$decision" ]; then
        printf 'FAIL  expected a prompt, got silence:  %s\n' "$command"
        failures=$((failures + 1))
      fi
      ;;
    pass)
      if [ -n "$decision" ]; then
        reason=$(printf '%s' "$decision" | jq -r '.hookSpecificOutput.permissionDecisionReason')
        printf 'FAIL  expected silence, got a prompt:  %s\n      %s\n' "$command" "$reason"
        failures=$((failures + 1))
      fi
      ;;
    *)
      printf 'FAIL  unknown expectation %s in:  %s\n' "$expect" "$line"
      failures=$((failures + 1))
      ;;
  esac
done < "$tests"

if [ "$failures" -gt 0 ]; then
  printf '\n%d command-guard case(s) failed\n' "$failures"
  exit 1
fi

printf 'command-guard: all cases pass\n'
