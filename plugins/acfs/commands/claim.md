---
description: Claim an issue and reserve required files for exclusive editing
argument-hint: "<issue-id>"
allowed-tools: Bash, Read, Grep, Glob, Skill
---

Claim an issue from the backlog, analyze required files, and reserve them to prevent edit conflicts.

**Requires:** Issue ID as `$ARGUMENTS`

## Workflow

### 1. Validate Issue Exists

```bash
br show "$ARGUMENTS" --robot --json
```

If issue not found, report error and suggest `/acfs:ready` to find available issues.

### 2. Check Issue Status

- If already `in-progress` by another agent: WARN and ask for confirmation
- If `done` or `closed`: ERROR - cannot claim completed issues
- If `blocked`: WARN about blocking issues

### 3. Analyze Required Files

Parse the issue description to identify likely files:
- Look for file paths mentioned in description
- Look for component/module names and map to file paths
- Use Grep to find related files if patterns mentioned

```bash
# Example: Find files related to "authentication"
grep -r "authentication\|auth\|login" --include="*.ts" --include="*.js" -l
```

Present the identified files to user for confirmation.

### 4. Check Existing Reservations

```bash
mcp_agent_mail leases --robot --json
```

For each file we want to reserve:
- If unreserved: Add to reservation list
- If reserved by us: Skip (already have it)
- If reserved by another agent: WARN and ask how to proceed
  - Option A: Message the agent to request release
  - Option B: Wait and retry later
  - Option C: Proceed without reserving (risky)

### 5. Reserve Files

For files confirmed to reserve:

```bash
mcp_agent_mail reserve --files "file1.ts,file2.ts,..." --lease 2h --robot --json
```

Default lease duration: 2 hours (can be extended with `/acfs:reserve`)

### 6. Update Issue Status

```bash
br update "$ARGUMENTS" --status in-progress --robot --json
```

### 7. Load Context (if available)

Check for relevant context:

```bash
# Search past sessions about this issue
cass search --query "issue $ARGUMENTS" --robot --json --limit 3

# Check for relevant memory/playbooks
cm context "$(br show $ARGUMENTS --field title)" --robot --json
```

### 8. Display Work Plan

```
Issue Claimed: $ARGUMENTS
========================

Title: [Issue title]
Priority: [P0-P4]
Description:
[Issue description]

Reserved Files (2h lease):
- src/auth/login.ts
- src/auth/token.ts

Related Context:
- Previous session on 2024-01-15 discussed similar issue
- Playbook "auth-patterns" may be relevant

Ready to begin work. Use /acfs:update to track progress.
When done: /acfs:complete to run quality gates and push.
```

### Error Handling

- If `br` command fails: Suggest running `/acfs:doctor` to verify toolchain
- If `mcp_agent_mail` fails: Proceed without reservations but WARN about potential conflicts
- If issue doesn't exist: List similar issues that might match
