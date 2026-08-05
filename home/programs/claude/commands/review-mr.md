---
allowed-tools: Bash(git log:*), Bash(git status:*)
description: Review a merge request
argument-hint: "<target-branch>"
---

## Context

- Current git status: !`git status`
- Current git diff (staged and unstaged changes): !`git diff HEAD`
- Current branch: !`git branch --show-current`
- Recent commits: !`git log --oneline -10`

## Your task

Diff the current branch against $1 and review the changes. Provide feedback on code quality, style, potential bugs, and adherence to best practices. Suggest improvements where applicable.
