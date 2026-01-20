---
name: session-persistence
description: Enables session persistence using CASS for search and CM for procedural memory. Use when needing context from past sessions or recalling learned patterns.
---

# Session Persistence

ACFS preserves context across sessions through CASS (session search) and CM (procedural memory).

## CASS - Session Search

CASS indexes conversations across all agent types (Claude Code, Codex, Cursor, Gemini, ChatGPT).

### Search Past Sessions
```bash
cass search \
  --query "authentication token refresh" \
  --robot --json \
  --limit 5
```

Returns matching sessions with:
- Session ID
- Timestamp
- Relevance score
- Key snippets

### View Session Details
```bash
cass view <session-id> --robot --json
```

Shows full session context.

### Expand Context
```bash
cass expand <session-id> --around <message-id> --robot --json
```

Gets surrounding context around a specific message.

### Search Patterns

**Find solutions:**
```bash
cass search --query "how to fix <error message>" --robot --json
```

**Find decisions:**
```bash
cass search --query "decided to use <technology>" --robot --json
```

**Find related work:**
```bash
cass search --query "issue ACFS-42" --robot --json
```

## CM - Procedural Memory

CM extracts lessons and playbooks from session history.

### Onboard to Memory System
```bash
# Check onboarding status
cm onboard status

# Sample sessions to process
cm onboard sample

# Read and learn from sessions
cm onboard read
```

### Retrieve Context
Before starting work, query for relevant memory:

```bash
cm context "<task description>" --robot --json
```

Returns:
- Relevant playbook rules
- Past lessons learned
- Applicable patterns

### Access Playbooks
```bash
# List playbooks
cm playbook list --robot --json

# View specific playbook
cm playbook show <name> --robot --json
```

Playbooks are structured procedures for common tasks.

### Add to Memory
After discovering something useful:

```bash
cm playbook add \
  --name "auth-token-patterns" \
  --rule "Always check token expiry before refresh" \
  --robot --json
```

### Feedback Loop
Reference rules during work and leave feedback:

```bash
cm feedback \
  --rule-id <id> \
  --useful true \
  --context "Applied successfully to ACFS-42" \
  --robot --json
```

## Session Workflow Integration

### At Session Start
```bash
# 1. Search for relevant past work
cass search --query "<current task>" --robot --json

# 2. Load applicable memory
cm context "<current task>" --robot --json

# 3. Check for handoffs
ls .beads/handoffs/*.md | tail -1 | xargs cat
```

### During Session
- Reference rule IDs from CM when applying patterns
- Note when past session context is helpful
- Create new playbook entries for discoveries

### At Session End
```bash
# Archive session for future search
cass archive --robot --json

# Add any new learnings to memory
cm playbook add --name "<topic>" --rule "<lesson>" --robot --json
```

## Context Loading Strategies

### Narrow Search
When you know what you're looking for:
```bash
cass search --query "exact error message" --limit 3 --robot --json
```

### Broad Search
When exploring a topic:
```bash
cass search --query "authentication" --limit 10 --robot --json
cm context "authentication patterns" --robot --json
```

### Issue-Focused
When working on specific issue:
```bash
cass search --query "ACFS-42" --robot --json
```

## Best Practices

- **Search before starting**: Always check for prior art
- **Load relevant memory**: Query CM for applicable patterns
- **Reference sources**: Note when using past context
- **Contribute back**: Add learnings to playbooks
- **Archive sessions**: Ensure searchability for future
