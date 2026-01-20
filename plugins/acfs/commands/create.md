---
description: Create a new issue in the Beads backlog
argument-hint: "<title> [--priority P0-P4] [--labels <labels>] [--type <type>]"
allowed-tools: Bash, Read
---

Create a structured issue for the Beads backlog.

## Arguments

Parse `$ARGUMENTS` for:
- `<title>`: Required - brief description (can be quoted)
- `--priority <P0-P4>`: Optional - priority level (default: P2)
- `--labels <labels>`: Optional - comma-separated labels
- `--type <type>`: Optional - bug, feature, task, epic, chore (default: task)
- `--description <text>`: Optional - detailed description

## Issue Types

| Type | Use For |
|------|---------|
| `bug` | Something broken that needs fixing |
| `feature` | New functionality to add |
| `task` | Generic work item |
| `epic` | Large effort spanning multiple issues |
| `chore` | Maintenance, cleanup, dependencies |

## Priority Levels

| Priority | Meaning | Response |
|----------|---------|----------|
| P0 | Critical | Drop everything |
| P1 | High | Work on next |
| P2 | Medium | Normal queue |
| P3 | Low | When time permits |
| P4 | Backlog | Someday/maybe |

## Workflow

### 1. Parse and Validate

Extract title from arguments. If title is missing, prompt for it.

### 2. Gather Context

If working on related code, automatically suggest:
- Relevant labels based on file paths
- Links to current issue if one is claimed

### 3. Create Issue

```bash
br create \
  --title "<title>" \
  --type <type> \
  --priority <priority> \
  --labels "<labels>" \
  --description "<description>" \
  --robot --json
```

### 4. Display Result

```
Issue Created
=============

ID: ACFS-99
Title: <title>
Type: <type>
Priority: <priority>
Labels: <labels>

To claim this issue: /acfs:claim ACFS-99
To view all ready issues: /acfs:ready
```

## Quick Create Patterns

```bash
# Simple task
/acfs:create "Update API documentation"

# Bug with priority
/acfs:create "Fix memory leak in worker" --priority P1 --type bug

# Feature with labels
/acfs:create "Add export to CSV" --type feature --labels "api,export"
```

## Linking Issues

If creating a blocker for current work:

```bash
/acfs:create "Deploy new API version" --blocks ACFS-42
```

This creates the new issue and links it as blocking ACFS-42.
