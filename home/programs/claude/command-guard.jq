# PreToolUse guard for Bash tool calls. Reads the hook payload on stdin and
# emits an "ask" decision when the command matches a destructive pattern, so the
# call becomes a permission prompt instead of running unattended.
#
# "ask" rather than "deny" on purpose. A false positive then costs one keystroke,
# where a false deny costs a wedged session and a config edit. It loses nothing:
# Claude Code evaluates the deny rules in settings.json regardless of what a hook
# returns, so those stay the hard backstop underneath this.
#
# Why a hook at all, given settings.json already denies `rm -rf`: permission
# rules match a literal command prefix, so they see `rm -rf` and miss `rm -fr`,
# `rm -r -f`, and `sudo rm -rf`. This works on parsed tokens instead, so flag
# spelling and order stop mattering.
#
# Everything below is deliberately narrower than a general-purpose guard. It
# covers the operations that are irreversible on the hosts in this repo, and
# nothing else. See command-guard-tests.txt for the contract, including the
# `pass` cases that keep it from prompting on ordinary work.

# Shell operators that begin a new command, so `foo && rm -rf x` is judged on the
# rm rather than on the foo. Command substitution parens are separators too, so
# `$(rm -rf x)` surfaces its inner command.
def segments:
  [ splits("\\|\\||&&|\\$\\(|[;&|`()\n]") ]
  | map(sub("^\\s+"; "") | sub("\\s+$"; ""))
  | map(select(length > 0));

def words: [ splits("\\s+") ] | map(select(length > 0));

# Quotes survive tokenization (there is no shell to strip them), so they are
# removed per-token before comparing against literal flags and paths.
def unquote: sub("^['\"]"; "") | sub("['\"]$"; "");

# Drops leading option tokens, consuming the operand of any option in $valued.
# Stops at the first non-option, which is the thing being wrapped.
def drop_options($valued):
  if length == 0 then .
  elif (.[0] | IN($valued[])) then .[2:] | drop_options($valued)
  elif (.[0] | test("^-")) then .[1:] | drop_options($valued)
  else .
  end;

# Leading env assignments and pass-through wrappers are dropped so `sudo rm` and
# `FORCE=1 rm` are judged as `rm`. sudo's own options go with it, including the
# operand of `-u`, so `sudo -u postgres psql` lands on psql. Wrappers that take
# positional arguments of their own (timeout, xargs, nice) are deliberately not
# unwrapped: skipping those correctly needs a real parser, and guessing wrong
# reads the operand as the command. They fall through to the settings.json rules.
def unwrap:
  if length == 0 then .
  elif (.[0] | test("^[A-Za-z_][A-Za-z0-9_]*=")) then .[1:] | unwrap
  elif (.[0] | IN("sudo", "doas")) then
    .[1:] | drop_options(["-u", "-g", "-p", "-C", "-r", "-t"]) | unwrap
  elif (.[0] | IN("env", "command", "builtin", "nohup")) then .[1:] | unwrap
  else .
  end;

# A short-flag cluster carrying $ch, so one test covers -f, -rf, -fr and -Rfv.
# `--force` is not matched here (the character after the second dash is `-`, not
# a letter), which is why long forms are listed separately at each use.
def short($ch): any(.args[]; test("^-[A-Za-z]*\($ch)"));
def has($flag): any(.args[]; . == $flag);
def arg($re): any(.args[]; test($re));

# Subcommands are matched anywhere in the argument list rather than at a fixed
# position, so global options keep working: `git -C /tmp/repo reset --hard`.
def subcmd($name): has($name);

def recursive: short("[rR]") or has("--recursive");
def force: short("f") or has("--force");

def reasons:
  [
    (select(.cmd == "rm" and recursive and force)
      | "rm with recursive and force flags"),
    (select(.cmd == "rm" and arg("^(/|~|\\$HOME|/[^/]+/?)$"))
      | "rm targeting a root-level or home path"),
    (select(.cmd == "shred" or .cmd == "wipefs")
      | "\(.cmd) destroys data unrecoverably"),

    (select(.cmd == "git" and subcmd("reset") and has("--hard"))
      | "git reset --hard discards uncommitted work"),
    (select(.cmd == "git" and subcmd("clean") and (short("f") or short("d") or short("x")))
      | "git clean deletes untracked files"),
    (select(.cmd == "git" and subcmd("checkout") and has("--") and arg("^\\.$"))
      | "git checkout -- . discards all local modifications"),
    (select(.cmd == "git" and subcmd("restore") and arg("^\\.$"))
      | "git restore . discards all local modifications"),
    (select(.cmd == "git" and subcmd("push") and (has("--force") or short("f")))
      | "git push --force can overwrite remote history"),
    (select(.cmd == "git" and subcmd("branch") and has("-D"))
      | "git branch -D deletes an unmerged branch"),
    (select(.cmd == "git" and subcmd("stash") and (subcmd("drop") or subcmd("clear")))
      | "git stash drop/clear is not recoverable"),
    (select(.cmd == "git" and (subcmd("filter-branch") or (subcmd("reflog") and subcmd("expire"))))
      | "git history rewrite"),

    (select((.cmd == "docker" or .cmd == "podman") and subcmd("prune"))
      | "\(.cmd) prune removes unused data"),
    (select((.cmd == "docker" or .cmd == "podman") and subcmd("volume") and subcmd("rm"))
      | "removing a container volume deletes its data"),
    (select((.cmd == "docker" or .cmd == "podman") and subcmd("down")
            and (has("-v") or has("--volumes")))
      | "compose down -v deletes the stack's volumes"),

    (select(.cmd == "restic" and (subcmd("forget") or subcmd("prune")))
      | "restic forget/prune deletes backup snapshots"),
    (select(.cmd == "dropdb") | "dropdb deletes a database"),
    # Matched against the raw segment: a statement like `DROP DATABASE x` spans
    # several whitespace-separated tokens, so no single argument contains it.
    (select(.raw | test("(?i)\\b(DROP\\s+(DATABASE|TABLE|SCHEMA)|TRUNCATE\\s+TABLE)"))
      | "destructive SQL statement"),

    (select(.cmd == "dd" and arg("^of=/dev/"))
      | "dd writing to a block device"),
    (select(.cmd | test("^mkfs(\\.|$)"))
      | "mkfs formats a filesystem"),
    (select(.cmd == "diskutil" and arg("(?i)^erase"))
      | "diskutil erase destroys a volume"),

    (select(.cmd == "find" and (has("-delete") or has("-exec") or has("-execdir")))
      | "find with a delete or exec action")
  ];

# ssh and `sh -c` take a whole command as an argument. Token rules can't see
# into that, so the payload is unwrapped and re-checked. This is scoped to
# commands that genuinely execute their argument, which is what keeps
# `rg 'rm -rf'` and `echo "rm -rf /"` from prompting.
def payload:
  if .cmd | IN("ssh", "mosh") then
    # Leading options go first (with their operands, so `ssh -p 2222 host cmd`
    # works), then the host. Only *leading* options may be dropped: filtering
    # options out of the whole list would strip the payload's own flags and turn
    # `ssh host rm -rf x` into a harmless-looking `rm x`.
    .args | drop_options(["-p", "-i", "-o", "-l", "-F", "-J", "-b", "-c", "-E", "-m", "-S", "-w", "-L", "-R", "-D"])
          | .[1:] | join(" ")
  elif (.cmd | IN("sh", "bash", "zsh", "dash")) and has("-c") then
    (.args | index("-c")) as $i | .args[$i + 1:] | join(" ")
  elif (.cmd | IN("docker", "podman")) and (.args | index("exec")) != null then
    (.args | index("exec")) as $i
    | .args[$i + 1:] | drop_options(["-e", "-u", "-w", "--env", "--user", "--workdir"])
                     | .[1:] | join(" ")
  else
    ""
  end;

# $depth bounds the recursion into carried commands; three levels is more
# nesting than anything real and stops a crafted payload from looping.
def check($depth):
  [ segments[]
    | . as $raw
    | words
    | unwrap
    | select(length > 0)
    | { cmd: (.[0] | unquote), args: (.[1:] | map(unquote)), raw: $raw }
    | reasons + (
        if $depth > 0 then
          (payload | select(length > 0) | check($depth - 1)) // []
        else
          []
        end
      )
  ]
  | flatten;

(.tool_input.command // "")
| check(3)
| unique
| select(length > 0)
| {
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: ("Destructive command guard: " + join("; "))
    }
  }
