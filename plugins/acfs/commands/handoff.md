---
description: Create handoff document for session continuation
argument-hint: "[--issue <id>] [notes]"
allowed-tools: Bash, Read, Write, Grep, Glob, Task
---

Create a comprehensive handoff document to enable session continuation.

**Delegate to:** `acfs:handoff-writer` agent

## Arguments

Parse `$ARGUMENTS` for:
- `--issue <id>`: Optional - specific issue to document (otherwise documents all in-progress)
- `[notes]`: Optional - additional context to include

## Workflow

### 1. Gather Session Context

Collect information about current session:

```bash
# Recent commits
git log --oneline -10

# Changed files
git diff --name-only HEAD~10..HEAD

# Current branch
git branch --show-current

# In-progress issues
br list --status in-progress --mine --robot --json
```

### 2. Delegate to Handoff Writer

Invoke the handoff-writer agent with context:

```
Create a handoff document for the current session.

Context:
- Branch: <branch>
- Recent commits: <commits>
- Modified files: <files>
- In-progress issues: <issues>
- User notes: <notes from arguments>

Write the handoff to: .beads/handoffs/<timestamp>-session.md

Include:
1. Summary of work completed
2. Current state of each in-progress issue
3. Key decisions made and rationale
4. Files modified with brief description of changes
5. Remaining work and next steps
6. Any blockers or dependencies
7. Notes for the next session
```

### 3. Verify and Report

```
Handoff Created
===============

Location: .beads/handoffs/2024-01-20-143022-session.md

Summary:
- 3 commits documented
- 2 in-progress issues covered
- 5 modified files noted

The handoff has been staged for commit.
Next session can load with: /acfs:recall
```

## Handoff Format

Handoffs follow a standard template:

```markdown
# Session Handoff - <timestamp>

## Session Overview
- Agent: <agent-id>
- Duration: <start> to <end>
- Branch: <branch>

## Work Completed
- [x] <completed task 1>
- [x] <completed task 2>

## In-Progress Issues

### ACFS-42: <title>
Status: <status>
Progress: <description>
Next: <next steps>

## Files Modified
| File | Changes |
|------|---------|
| src/auth/login.ts | Refactored token handling |

## Key Decisions
1. <Decision and rationale>

## Remaining Work
- [ ] <todo 1>
- [ ] <todo 2>

## Blockers
- <blocker if any>

## Notes for Next Session
<any additional context>
```

## When to Create Handoffs

- Before ending any session
- Before context-switching to different work
- When blocked and pausing work
- When another agent will continue your work
