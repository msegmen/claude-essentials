---
description: Retrieve procedural memory and playbooks from CM
argument-hint: "<topic> [--playbook <name>] [--add]"
allowed-tools: Bash, Read, Write
---

Access learned patterns and procedural knowledge from the CM memory system.

## Arguments

Parse `$ARGUMENTS` for:
- `<topic>`: Query topic for context retrieval
- `--playbook <name>`: View specific playbook
- `--list`: List available playbooks
- `--add`: Add new rule to memory

## Retrieve Context

Query CM for relevant memory:

```bash
cm context "<topic>" --robot --json
```

Display results:

```
Memory Context
==============

Topic: "authentication patterns"

Relevant Rules:
---------------

[Rule #42] auth-patterns
"Always check token expiry before attempting refresh"
Applied: 12 times | Last: 2024-01-18 | Useful: 92%

[Rule #38] error-handling
"Wrap auth operations in try-catch with specific error types"
Applied: 8 times | Last: 2024-01-17 | Useful: 88%

Related Playbooks:
- auth-token-handling (5 rules)
- api-error-patterns (3 rules)

To view playbook: /acfs:recall --playbook auth-token-handling
```

## View Playbook

```bash
cm playbook show <name> --robot --json
```

```
Playbook: auth-token-handling
=============================

Rules:
1. Check token expiry 5 minutes before actual expiry
2. Use silent refresh when possible for better UX
3. Store refresh token securely, never in localStorage
4. Implement retry with exponential backoff for refresh failures
5. Clear all tokens on logout, including from memory

Reference Sessions:
- abc123 (2024-01-18)
- def456 (2024-01-15)
```

## List Playbooks

```bash
cm playbook list --robot --json
```

```
Available Playbooks
===================

auth-token-handling    | 5 rules | Last updated: 2024-01-18
api-error-patterns     | 3 rules | Last updated: 2024-01-17
database-migrations    | 7 rules | Last updated: 2024-01-10
testing-patterns       | 4 rules | Last updated: 2024-01-08
git-workflow           | 6 rules | Last updated: 2024-01-05
```

## Add to Memory

When you discover something useful:

```bash
cm playbook add \
  --name "<playbook>" \
  --rule "<rule description>" \
  --robot --json
```

Example:
```
/acfs:recall --add auth-patterns "Always validate token signature on the server, never trust client-side validation"
```

## Load Handoffs

Also useful for loading recent handoffs:

```bash
# Find latest handoff
ls -t .beads/handoffs/*.md | head -1

# Display content
cat .beads/handoffs/<latest>.md
```

```
Latest Handoff
==============

File: .beads/handoffs/2024-01-20-session.md

[Contents of handoff displayed]
```

## Workflow Integration

At session start:
```bash
# Load relevant memory
/acfs:recall "current task topic"

# Check for handoffs
/acfs:recall --handoff
```

During work:
- Reference rule IDs when applying patterns
- Note when patterns are helpful

At session end:
- Add new learnings with `--add`
