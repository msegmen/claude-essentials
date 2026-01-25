---
description: Fix a GitHub issue by number
argument-hint: "<issue-number> [--worktree]"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Task
---

Fix a GitHub issue using TDD methodology.

## Arguments

- `$ARGUMENTS`: Issue number (e.g., "123" or "#123") and optional flags
  - `--worktree`: Create isolated git worktree for this fix

## Process

### 1. Fetch Issue Details

```bash
gh issue view <number> --json title,body,labels,comments
```

- Understand what's being requested or what bug is reported
- Check labels for context (bug, feature, enhancement, etc.)
- Review comments for additional context or constraints
- Identify acceptance criteria if specified

### 2. Setup Workspace (if --worktree flag)

Follow @superpowers:using-git-worktrees to create an isolated workspace:

- Branch name: `fix/issue-<number>`
- Directory: Follow skill's priority order (existing `.worktrees/` → CLAUDE.md → ask)
- Verify directory is gitignored
- Run project setup (npm install, etc.)
- Verify baseline tests pass

### 3. Analyze the Codebase

- Find relevant files mentioned in or related to the issue
- Understand the current implementation
- Identify where changes need to be made
- Note existing test patterns for consistency

### 4. Implement with TDD

Follow @superpowers:test-driven-development strictly.

**For bug fixes:**
1. **RED**: Write a failing test that reproduces the bug
   - Test must fail with expected error
   - Watch it fail before proceeding
2. **GREEN**: Write minimal code to make the test pass
3. **REFACTOR**: Clean up while staying green

**For feature requests:**
1. **RED**: Write a failing test for the first behavior slice
2. **GREEN**: Implement just enough to pass
3. **REFACTOR**: Clean up
4. **Repeat** for each additional behavior

**Enforcement:**
- No implementation code without a failing test first
- If test passes immediately, rewrite the test
- Announce each phase: "RED: Writing failing test...", "GREEN: Implementing..."

### 5. Verify and Summarize

- Run full test suite - all tests must pass
- List files changed
- Explain the approach taken
- Note any follow-up items or considerations

Do not automatically commit or create a PR. Let the user review the changes first.

If the issue number is not provided or cannot be found, ask for clarification.
