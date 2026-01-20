---
description: Search past sessions using CASS
argument-hint: "<query> [--limit <n>] [--since <date>]"
allowed-tools: Bash, Read
---

Search across all past agent sessions for relevant context.

## Arguments

Parse `$ARGUMENTS` for:
- `<query>`: Required - search query
- `--limit <n>`: Optional - max results (default: 5)
- `--since <date>`: Optional - only sessions after date
- `--repo <name>`: Optional - filter to specific repository

## Workflow

### 1. Execute Search

```bash
cass search \
  --query "<query>" \
  --limit <limit> \
  --since "<since>" \
  --robot --json
```

### 2. Parse Results

Extract from each result:
- Session ID
- Timestamp
- Agent type (Claude Code, Codex, etc.)
- Relevance score
- Matching snippets

### 3. Display Results

```
Session Search Results
======================

Query: "authentication token refresh"
Found: 8 sessions (showing top 5)

1. [0.92] Session abc123 | 2024-01-18 | Claude Code
   "...implemented token refresh using the refresh_token endpoint..."
   View: cass view abc123

2. [0.87] Session def456 | 2024-01-15 | Codex
   "...the auth module handles token expiry by checking the exp claim..."
   View: cass view def456

3. [0.81] Session ghi789 | 2024-01-10 | Claude Code
   "...decided to use silent refresh for better UX..."
   View: cass view ghi789

To view full session: /acfs:search --view <session-id>
To expand context: cass expand <session-id> --around <msg-id>
```

### 4. View Session Detail

If `--view <session-id>` provided:

```bash
cass view <session-id> --robot --json
```

Display formatted session transcript.

## Search Patterns

```bash
# Find error solutions
/acfs:search "TypeError: Cannot read property"

# Find decisions
/acfs:search "decided to use" --since 2024-01-01

# Find issue context
/acfs:search "ACFS-42"

# Find API patterns
/acfs:search "authentication API" --limit 10

# Recent sessions only
/acfs:search "database migration" --since 2024-01-15
```

## Tips

- Use specific error messages for exact matches
- Include technology names for better filtering
- Reference issue IDs to find related work
- Use quotes for exact phrase matching
- Combine with `/acfs:recall` for procedural memory
