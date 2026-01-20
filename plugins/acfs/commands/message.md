---
description: Send message to another agent or view inbox
argument-hint: "[<agent-id> <message>] [--inbox] [--priority high|normal]"
allowed-tools: Bash, Read
---

Inter-agent messaging for coordination.

## Arguments

Parse `$ARGUMENTS` for:
- `--inbox`: View your message inbox
- `<agent-id> <message>`: Send message to specific agent
- `--priority <high|normal>`: Message priority (default: normal)
- `--reply <thread-id>`: Reply to existing thread

## View Inbox

If `--inbox` or no arguments:

```bash
mcp_agent_mail inbox --robot --json
```

Display messages:

```
Inbox (3 messages)
==================

[UNREAD] From: agent-42 | Priority: HIGH | 10 min ago
Thread: abc123
"Can you release src/auth/login.ts? I need to fix a bug."

[READ] From: agent-15 | Priority: normal | 2 hours ago
Thread: def456
"FYI: Refactored the token module, tests all pass."

[READ] From: agent-8 | Priority: normal | 1 day ago
Thread: ghi789
"Thanks for the handoff notes!"

To reply: /acfs:message --reply <thread-id> "your message"
```

## Send Message

```bash
mcp_agent_mail send \
  --to <agent-id> \
  --message "<message>" \
  --priority <priority> \
  --robot --json
```

Display confirmation:

```
Message Sent
============

To: agent-42
Priority: normal
Thread: xyz789

Message: "Sure, releasing login.ts now. All yours!"

Waiting for reply...
```

## Reply to Thread

```bash
mcp_agent_mail reply \
  --thread <thread-id> \
  --message "<message>" \
  --robot --json
```

## List Active Agents

Before messaging, see who's active:

```bash
mcp_agent_mail agents --robot --json
```

```
Active Agents
=============

agent-42 | Active | Working on: ACFS-55
  Reserved: src/auth/login.ts, src/auth/token.ts

agent-15 | Active | Working on: ACFS-38
  Reserved: src/api/routes.ts

agent-8 | Idle | Last seen: 2 hours ago
  No reservations
```

## Common Patterns

```bash
# Check inbox
/acfs:message --inbox

# Request file release
/acfs:message agent-42 "Can you release login.ts when done?"

# Urgent coordination
/acfs:message agent-42 "BLOCKING: Need auth module for P0 fix" --priority high

# Reply to thread
/acfs:message --reply abc123 "Released, it's all yours"

# FYI notification
/acfs:message agent-15 "FYI: Changed API response format, check your tests"
```

## Priority Guidelines

- **high**: You're blocked waiting for response
- **normal**: Regular coordination (default)

High priority messages may trigger notifications.
