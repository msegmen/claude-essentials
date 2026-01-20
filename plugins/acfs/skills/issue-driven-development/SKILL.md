---
name: issue-driven-development
description: Implements issue-driven development workflow using Beads for tracking. Use when finding work, claiming issues, updating progress, or closing completed work.
---

# Issue-Driven Development

All work flows through Beads issues. This ensures traceability, enables coordination, and provides historical context.

## Issue Lifecycle

```
ready → claimed → in-progress → review → done
                      ↓
                   blocked → (resolve) → in-progress
```

## Finding Work

```bash
# List ready issues
br ready --robot --json

# Filter by priority
br ready --priority P1 --robot --json

# Filter by label
br ready --label bugfix --robot --json
```

Priority levels:
- **P0**: Critical - drop everything
- **P1**: High - work on next
- **P2**: Medium - normal queue
- **P3**: Low - when time permits
- **P4**: Backlog - someday/maybe

## Claiming Issues

Before starting work:

```bash
# View issue details
br show <issue-id> --robot --json

# Update status to claim
br update <issue-id> --status in-progress --robot --json
```

Always claim before starting to prevent duplicate work.

## Progress Tracking

Update regularly, especially:
- When significant progress made
- When blocked
- When context-switching
- Before ending session

```bash
br update <issue-id> --notes "Completed auth refactor" --robot --json
br update <issue-id> --status blocked --notes "Waiting on API" --robot --json
```

## Blocking Issues

When blocked by another issue:

```bash
# Create blocking issue
br create --title "Blocking: <description>" --blocks <issue-id> --robot --json

# Update original issue
br update <issue-id> --status blocked --blocked-by <blocker-id> --robot --json
```

## Closing Issues

Only close when:
1. Work is complete
2. Tests pass
3. Code is pushed

```bash
br close <issue-id> --robot --json
br sync --flush-only
```

## Creating Issues

For new work discovered:

```bash
br create \
  --title "Brief description" \
  --priority P2 \
  --labels "feature,api" \
  --description "Detailed description..." \
  --robot --json
```

## Issue Types

| Type | Use For |
|------|---------|
| `bug` | Something broken |
| `feature` | New functionality |
| `task` | Generic work item |
| `epic` | Large multi-issue effort |
| `chore` | Maintenance/cleanup |

## Best Practices

### Atomic Issues
- One logical change per issue
- If issue grows, split it

### Clear Titles
- Start with verb: "Add...", "Fix...", "Update..."
- Be specific: "Fix auth token expiry" not "Fix auth"

### Link Related Work
- Reference related issues in description
- Use `--blocks` and `--blocked-by` for dependencies

### Handoff Notes
- Always add notes before context switch
- Include "what's next" in notes

## Beads Directory

Issues stored in `.beads/`:
```
.beads/
├── issues/
│   ├── ACFS-001.yaml
│   ├── ACFS-002.yaml
│   └── ...
├── handoffs/
│   └── 2024-01-20-session.md
└── config.yaml
```

Always commit `.beads/` changes with your code.
