---
description: Sync multiple related repositories
argument-hint: "[--status] [--pull] [--repos <list>]"
allowed-tools: Bash, Read
---

Multi-repository synchronization using Repo Updater (RU).

## Arguments

Parse `$ARGUMENTS` for:
- `--status`: Show sync status for all configured repos
- `--pull`: Pull latest changes for all repos
- `--repos <list>`: Specific repos to sync (comma-separated)
- `--push`: Push all pending changes

## Workflow

### 1. Show Status

```bash
ru status --robot --json
```

Display:

```
Repository Status
=================

Repo                 | Branch      | Status        | Behind/Ahead
---------------------|-------------|---------------|-------------
frontend             | main        | clean         | 0/0
backend-api          | main        | 2 uncommitted | 0/3
shared-libs          | feature/auth| clean         | 5/0
infrastructure       | main        | clean         | 0/0

Legend: Behind = commits to pull, Ahead = commits to push

Recommendations:
- backend-api: Commit or stash changes, then push 3 commits
- shared-libs: Pull 5 new commits from remote
```

### 2. Pull Updates

```bash
ru sync --pull --robot --json
```

```
Pulling Updates
===============

frontend: Already up to date
backend-api: Skipped (uncommitted changes)
shared-libs: Pulled 5 commits
  - abc123: Fix auth token validation
  - def456: Add rate limiting
  - ghi789: Update dependencies
  - jkl012: Refactor middleware
  - mno345: Add tests
infrastructure: Already up to date

Summary: 1 repo updated, 1 skipped, 2 unchanged
```

### 3. Push Changes

```bash
ru sync --push --robot --json
```

```
Pushing Changes
===============

frontend: Nothing to push
backend-api: Pushed 3 commits to origin/main
shared-libs: Nothing to push
infrastructure: Nothing to push

Summary: 1 repo pushed
```

### 4. Full Sync

```bash
ru sync --robot --json
```

Performs pull then push for all repos.

## Exit Codes

- `0`: All repos synced successfully
- `1`: Partial success (some repos had issues)
- `2`: Conflicts detected (manual resolution needed)
- `5`: Interrupted (resume with `ru sync --continue`)

## Conflict Handling

If conflicts detected:

```
Conflict in shared-libs
=======================

Files with conflicts:
- src/auth/index.ts

Options:
1. Resolve manually, then: ru sync --continue
2. Abort this repo: ru sync --skip shared-libs
3. Show conflict details: git diff shared-libs

What would you like to do?
```

## Configuration

Repos are configured in `.acfs/repos.yaml`:

```yaml
repos:
  - name: frontend
    path: ../frontend
    remote: origin
    branch: main
  - name: backend-api
    path: ../backend
    remote: origin
    branch: main
```

## Quick Patterns

```bash
# Check status before starting work
/acfs:sync --status

# Pull latest before starting
/acfs:sync --pull

# Sync specific repos
/acfs:sync --repos "frontend,backend-api" --pull

# Full sync at end of session
/acfs:sync
```
