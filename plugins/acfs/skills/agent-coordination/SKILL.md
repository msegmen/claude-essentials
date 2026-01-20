---
name: agent-coordination
description: Coordinates multi-agent work using MCP Agent Mail for file reservations, messaging, and identity management. Use when working alongside other agents or needing exclusive file access.
---

# Agent Coordination

When multiple agents work on the same codebase, coordination prevents conflicts and enables collaboration.

## Identity Management

### Register Identity
Every session should register:

```bash
mcp_agent_mail identity --register --robot --json
```

Returns your agent ID for this session.

### Check Active Agents
```bash
mcp_agent_mail agents --robot --json
```

Lists all currently active agents and their claimed files.

## File Reservations

### Reserve Files Before Editing

```bash
mcp_agent_mail reserve \
  --files "src/auth/login.ts,src/auth/token.ts" \
  --lease 2h \
  --robot --json
```

- **Lease duration**: Default 2h, extend if needed
- **Files**: Comma-separated paths
- **Purpose**: Prevents concurrent edits to same files

### Check Existing Reservations
```bash
mcp_agent_mail leases --robot --json
```

Before editing any file, check if reserved:
- If unreserved: Safe to edit, consider reserving
- If reserved by you: Safe to edit
- If reserved by another: DO NOT EDIT - coordinate first

### Extend Lease
```bash
mcp_agent_mail extend --files "src/auth/login.ts" --lease 1h --robot --json
```

### Release Reservations
```bash
# Release specific files
mcp_agent_mail release --files "src/auth/login.ts" --robot --json

# Release all your reservations
mcp_agent_mail release --all --robot --json
```

**Always release** when:
- Done editing files
- Ending session
- No longer need exclusive access

## Inter-Agent Messaging

### Send Message
```bash
mcp_agent_mail send \
  --to <agent-id> \
  --message "Can you release auth/login.ts when done?" \
  --priority normal \
  --robot --json
```

Priority levels:
- `high`: Blocking on response
- `normal`: Regular coordination
- `low`: FYI only

### Check Inbox
```bash
mcp_agent_mail inbox --robot --json
```

Check inbox at session start and periodically.

### Reply to Message
```bash
mcp_agent_mail reply \
  --thread <thread-id> \
  --message "Released, it's all yours" \
  --robot --json
```

## Coordination Patterns

### Pattern 1: Request File Access
```
1. Check leases: mcp_agent_mail leases
2. If reserved by agent-X:
   - Send message: "Need access to file.ts, ETA?"
   - Wait for reply
   - Claim when released
3. If unreserved:
   - Reserve immediately
   - Proceed with work
```

### Pattern 2: Handoff Files
```
1. Complete your changes
2. Commit and push
3. Release reservation: mcp_agent_mail release --files ...
4. Message waiting agent: "file.ts released"
```

### Pattern 3: Parallel Work
```
1. At session start: Reserve your working files
2. Check for conflicts with others' reservations
3. If overlap: Coordinate to divide work
4. Work independently on your reserved files
5. At session end: Release all
```

## Conflict Resolution

### File Conflict
Both agents need same file:
1. Message to discuss
2. Options:
   - Sequential: One finishes first
   - Divide: Split file or functionality
   - Pair: Work together in same session

### Message Conflict
Disagreement on approach:
1. Discuss via messages
2. If unresolved: Create issue to track decision
3. Escalate to human if needed

## Best Practices

- **Reserve early**: Claim files at work start
- **Release promptly**: Don't hold reservations longer than needed
- **Check before edit**: Always verify file isn't reserved
- **Communicate**: Message when blocking or blocked
- **Short leases**: Use 2h default, extend only if needed
