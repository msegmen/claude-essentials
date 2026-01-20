---
description: Execute session completion protocol with quality gates and mandatory push
argument-hint: "[--skip-push] [--skip-handoff] [--issue <id>]"
allowed-tools: Bash, Read, Write, Grep, Glob, Task, Skill
---

Execute the ACFS session completion protocol. This ensures all work is properly committed, pushed, and handed off.

**Load skill first:** `Skill(acfs:session-completion)`

## Arguments

Parse `$ARGUMENTS` for:
- `--skip-push`: Skip the mandatory push (NOT RECOMMENDED - use only if offline)
- `--skip-handoff`: Skip handoff document creation
- `--issue <id>`: Specific issue to close (otherwise closes all in-progress issues for this agent)

## Completion Protocol

### Phase 1: Quality Gates

Run each gate in sequence. ALL must pass before proceeding.

**1.1 Tests**
```bash
# Detect test runner and execute
npm test || yarn test || bun test || pytest || go test ./... || cargo test
```
- PASS: Continue
- FAIL: Stop and report failures. Do not proceed until fixed.

**1.2 Build**
```bash
# Detect build system and execute
npm run build || yarn build || bun run build || cargo build || go build ./...
```
- PASS: Continue
- FAIL: Stop and report errors. Do not proceed until fixed.

**1.3 Lint**
```bash
# Detect linter and execute
npm run lint || yarn lint || eslint . || cargo clippy || golangci-lint run
```
- PASS: Continue
- WARN: Report warnings but can proceed
- FAIL: Stop for errors

**1.4 UBS Scan**
```bash
ubs scan --staged --robot --json
```
- PASS (exit 0): Continue
- FAIL: Report issues. Critical issues block proceed. Warnings can be acknowledged.

### Phase 2: Git Verification

**2.1 Check Status**
```bash
git status --porcelain
```

If uncommitted changes exist:
- Stage and commit with descriptive message
- Include issue ID in commit message

**2.2 Verify Pushed (MANDATORY)**
```bash
git push
```

If `--skip-push` NOT provided, push is MANDATORY. Work is NOT complete until push succeeds.

If push fails:
- Check for conflicts: `git pull --rebase`
- Retry push
- If still fails: Report error, do NOT mark complete

### Phase 3: Release Reservations

```bash
mcp_agent_mail release --all --robot --json
```

Release all file reservations held by this agent.

### Phase 4: Close Issues

For each in-progress issue (or specified `--issue`):

```bash
br close <issue-id> --robot --json
```

Sync beads to remote:
```bash
br sync --flush-only
git add .beads/
git commit -m "chore: sync beads state"
git push
```

### Phase 5: Create Handoff (unless --skip-handoff)

Delegate to handoff-writer agent:

```
Create a handoff document for session completion.

Include:
- Summary of work completed (from git log)
- Issues closed in this session
- Any remaining tasks or follow-ups
- Important decisions made
- Files modified

Write to: .beads/handoffs/<timestamp>.md
```

### Phase 6: Archive Session

```bash
cass archive --robot --json
```

Archive this session for future searchability.

### Output

```
Session Completion
==================

Quality Gates:
  [PASS] Tests - 42 passed, 0 failed
  [PASS] Build - completed in 12s
  [PASS] Lint - no errors
  [PASS] UBS Scan - no critical issues

Git Status:
  [PASS] All changes committed
  [PASS] Pushed to origin/main (3 commits)

Reservations:
  [PASS] Released 2 file reservation(s)

Issues:
  [PASS] Closed ACFS-42: Fix auth token refresh
  [PASS] Closed ACFS-43: Add retry logic

Handoff:
  [PASS] Created .beads/handoffs/2024-01-20-session.md

Session archived. All work complete and pushed.
```

## Error Recovery

If any phase fails:
1. Report which phase failed and why
2. Provide fix command
3. Suggest re-running `/acfs:complete` after fix

Never mark complete if:
- Tests fail
- Push fails (unless --skip-push)
- Critical UBS issues found
