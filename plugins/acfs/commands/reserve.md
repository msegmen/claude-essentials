---
description: Reserve files for exclusive editing
argument-hint: "<file-patterns> [--lease <duration>]"
allowed-tools: Bash, Glob
---

Reserve files to prevent edit conflicts with other agents.

## Arguments

Parse `$ARGUMENTS` for:
- `<file-patterns>`: Required - file paths or glob patterns
- `--lease <duration>`: Optional - lease duration (default: 2h)

Duration formats: `30m`, `1h`, `2h`, `4h`

## Workflow

### 1. Expand File Patterns

If glob patterns provided, expand them:

```bash
# Example: src/auth/*.ts expands to actual files
```

List the files that will be reserved.

### 2. Check Existing Reservations

```bash
mcp_agent_mail leases --robot --json
```

For each file:
- **Unreserved**: Can reserve
- **Reserved by you**: Already have it
- **Reserved by another**: Report conflict

### 3. Handle Conflicts

If files reserved by another agent:

```
Conflict Detected
=================

The following files are reserved by other agents:

File: src/auth/login.ts
Reserved by: agent-42
Expires: 2024-01-20 15:30:00

Options:
1. Message agent-42 to request release: /acfs:message agent-42 "..."
2. Wait for lease to expire
3. Reserve remaining unreserved files only

What would you like to do?
```

### 4. Reserve Files

```bash
mcp_agent_mail reserve \
  --files "file1.ts,file2.ts,..." \
  --lease <duration> \
  --robot --json
```

### 5. Display Confirmation

```
Files Reserved
==============

Reserved (2h lease):
- src/auth/login.ts
- src/auth/token.ts
- src/auth/refresh.ts

Lease expires: 2024-01-20 16:30:00

To extend: /acfs:reserve <files> --lease 1h
To release: mcp_agent_mail release --files "..."
Session end releases automatically via /acfs:complete
```

## Common Patterns

```bash
# Reserve specific file
/acfs:reserve src/auth/login.ts

# Reserve multiple files
/acfs:reserve "src/auth/login.ts,src/auth/token.ts"

# Reserve with glob
/acfs:reserve "src/auth/*.ts"

# Longer lease for big refactor
/acfs:reserve "src/api/**/*.ts" --lease 4h
```

## Best Practices

- Reserve at start of work on files
- Use shortest reasonable lease
- Release when done (or use /acfs:complete)
- Check conflicts before editing any file
