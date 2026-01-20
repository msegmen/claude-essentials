---
description: Update issue progress with status and notes
argument-hint: "<issue-id> [--status <status>] [--notes <notes>]"
allowed-tools: Bash, Read
---

Record progress on a claimed issue. Update status and add notes for handoff context.

## Arguments

Parse `$ARGUMENTS` for:
- `<issue-id>`: Required - the issue to update
- `--status <status>`: Optional - new status (in-progress, blocked, review, done)
- `--notes <notes>`: Optional - progress notes (quoted string)

If only issue-id provided, prompt for what to update.

## Valid Statuses

| Status | Meaning |
|--------|---------|
| `in-progress` | Actively being worked on |
| `blocked` | Waiting on something (will prompt for blocker) |
| `review` | Ready for review/testing |
| `done` | Work complete (use /acfs:complete instead for full protocol) |

## Workflow

### 1. Validate Issue

```bash
br show <issue-id> --robot --json
```

Verify issue exists and current status.

### 2. Apply Updates

```bash
br update <issue-id> --status <status> --notes "<notes>" --robot --json
```

### 3. Handle Special Cases

**If status = blocked:**
- Prompt for blocking reason
- Suggest creating a linked blocking issue
- Offer to notify other agents if blocked on their work

```bash
br create --title "Blocking: <description>" --blocks <issue-id> --robot --json
```

**If status = done:**
- WARN: Recommend using `/acfs:complete` instead for full quality gates
- If user confirms direct done: Update status but remind about push

### 4. Display Confirmation

```
Issue Updated: <issue-id>
=========================

Previous Status: in-progress
New Status: blocked
Notes: Waiting for API endpoint to be deployed

Blocking Issue Created: ACFS-99 (linked)

Next Steps:
- Monitor blocking issue: br show ACFS-99
- When unblocked: /acfs:update <issue-id> --status in-progress
```

## Quick Update Patterns

Common patterns for easy updates:

```
/acfs:update ACFS-42 --notes "Completed auth refactor, starting tests"
/acfs:update ACFS-42 --status review --notes "Ready for code review"
/acfs:update ACFS-42 --status blocked --notes "Waiting on API deployment"
```

## Bulk Update

If no issue-id provided, show all in-progress issues for this agent and offer to update them:

```bash
br list --status in-progress --mine --robot --json
```
