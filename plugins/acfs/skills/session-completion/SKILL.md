---
name: session-completion
description: Enforces ACFS session completion protocol with quality gates, mandatory push, and handoff creation. Use when finishing a work session or before switching context.
---

# Session Completion Protocol

The ACFS session completion protocol ensures all work is properly validated, committed, pushed, and documented before ending a session.

## Core Principle

**Work is NOT complete until `git push` succeeds.**

Unpushed commits are invisible to other agents and at risk of loss. The push is mandatory, not optional.

## Quality Gates Checklist

Execute in order. All must pass.

### 1. Tests
```bash
# Run project test suite
npm test || yarn test || bun test || pytest || go test ./... || cargo test
```
- **PASS**: All tests pass
- **FAIL**: Stop. Fix failing tests before proceeding.

### 2. Build
```bash
# Run project build
npm run build || yarn build || bun run build || cargo build --release
```
- **PASS**: Build succeeds without errors
- **FAIL**: Stop. Fix build errors before proceeding.

### 3. Lint
```bash
# Run linter
npm run lint || eslint . || cargo clippy || golangci-lint run
```
- **PASS**: No lint errors
- **WARN**: Warnings acceptable, errors block

### 4. UBS Scan
```bash
ubs scan --staged --robot --json
```
- **PASS**: Exit code 0, no critical issues
- **FAIL**: Critical issues found - must address

## Git Protocol

### Commit All Changes
```bash
git add -A
git commit -m "feat(scope): description

Closes #<issue-id>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Mandatory Push
```bash
git pull --rebase origin main
git push origin HEAD
```

If push fails due to conflicts:
1. Resolve conflicts
2. Run tests again
3. Retry push

**Never skip the push** unless explicitly offline with `--skip-push`.

## Release Protocol

### File Reservations
```bash
mcp_agent_mail release --all --robot --json
```

Release all file reservations before ending session.

### Issue Closure
```bash
br close <issue-id> --robot --json
br sync --flush-only
git add .beads/
git commit -m "chore: sync beads state"
git push
```

## Handoff Document

Create handoff for session continuity:

**Location**: `.beads/handoffs/<YYYY-MM-DD>-<session-id>.md`

**Template**:
```markdown
# Session Handoff - <date>

## Completed Work
- [List of completed tasks with issue IDs]

## Files Modified
- [List of files changed]

## Key Decisions
- [Important decisions made and rationale]

## Remaining Work
- [Any incomplete tasks]

## Notes for Next Session
- [Context needed to continue]
```

## Verification Sequence

```
1. [ ] Tests pass
2. [ ] Build succeeds
3. [ ] Lint clean
4. [ ] UBS scan clean
5. [ ] All changes committed
6. [ ] Changes pushed to remote
7. [ ] File reservations released
8. [ ] Issues closed and synced
9. [ ] Handoff document created
10. [ ] Session archived to CASS
```

## Never Complete Without

- All tests passing
- Successful push to remote
- Released file reservations
- Updated issue status

## Error Recovery

If gate fails:
1. Report failure clearly
2. Provide fix command
3. Re-run `/acfs:complete` after fix

Do not partially complete - either all gates pass or session remains incomplete.
