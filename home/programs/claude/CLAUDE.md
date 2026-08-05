# Working with me

- Never run `git commit` or `git push` unless I explicitly ask. After making changes, stop and let me decide when to commit.
- Never add a `Co-Authored-By` trailer (or any equivalent attribution) to commit messages.
- When a CLI tool isn't installed, run it via `nix run nixpkgs#...` instead of installing it.
- Keep code comments concise, and explain "why" rather than "what" or "how".
- Update relevant docs (README, inline comments) when changing the codebase.
- Write the failing test first and work in red-green-refactor cycles. Trivial changes can skip this.
- Use existing project-specific tooling for linting, formatting, and testing.
- Use existing code as guidelines for style and patterns. Avoid introducing new patterns unless necessary.
- Add dependencies only when necessary, and check the latest available version first.
- Avoid typical LLM-isms in prose, e.g. em-dashes, listings of threes, "it's not $this, it's $that", bullet point lists with bolded first words, etc.
- We live by the boyscout rule, i.e. "leave the codebase cleaner than you found it".
- Researching online is always an option, use it when it helps.

If in doubt, ask me.
