---
description: Find available work from the Beads issue backlog
argument-hint: "[--label <label>] [--priority <P0-P4>]"
allowed-tools: Bash, Read
---

Query the Beads issue backlog for work that is ready to be claimed.

## Workflow

### 1. Query Available Issues

Run the Beads ready command:

```bash
br ready --robot --json
```

Parse the JSON output to extract issues. Each issue contains:
- `id`: Issue identifier
- `title`: Issue title
- `priority`: P0 (critical) through P4 (backlog)
- `labels`: Tags/categories
- `complexity`: Estimated effort
- `created`: Creation timestamp

### 2. Filter Results (if arguments provided)

If `$ARGUMENTS` includes filters:
- `--label <label>`: Filter to issues with matching label
- `--priority <P0-P4>`: Filter to issues at or above priority level

### 3. Check File Reservations

For each candidate issue, check if required files have active reservations:

```bash
mcp_agent_mail leases --robot --json
```

Mark issues as potentially blocked if their likely files are reserved by another agent.

### 4. Display Results

Format output as a table:

```
Available Work (Beads)
======================

Priority | ID      | Title                          | Labels        | Notes
---------|---------|--------------------------------|---------------|-------
P1       | ACFS-42 | Fix auth token refresh         | auth, bugfix  |
P2       | ACFS-38 | Add rate limiting to API       | api, feature  | files reserved by agent-7
P3       | ACFS-55 | Update documentation           | docs          |

Total: 3 issues ready for work

To claim an issue: /acfs:claim <issue-id>
```

### 5. Suggest Next Steps

- If issues available: Suggest `/acfs:claim <id>` for the highest priority unblocked issue
- If no issues: Suggest `/acfs:create` to add new work or check if all issues are in-progress
- If files reserved: Suggest `/acfs:message` to coordinate with the reserving agent
