---
name: two-person-rule
description: Enforces two-person rule using SLB for sensitive operations. Use when making changes that require verification by a second agent.
---

# Two-Person Rule (SLB)

The Simultaneous Launch Button (SLB) enforces verification by a second agent for sensitive operations.

## When Two-Person Rule Applies

### Destructive Operations
- Database schema drops
- Production data deletion
- Irreversible migrations
- Force push to protected branches

### High-Impact Changes
- Security configuration changes
- Authentication/authorization logic
- Payment processing code
- Data encryption changes

### Compliance Requirements
- PCI-DSS covered operations
- HIPAA protected data access
- SOC2 auditable actions

## SLB Workflow

### 1. Initiator Requests Approval

```bash
slb request \
  --operation "database migration: drop users_legacy table" \
  --files "migrations/drop_legacy.sql" \
  --robot --json
```

Creates approval request with:
- Operation description
- Affected files
- Timestamp
- Initiator ID

### 2. Request Broadcast

SLB notifies available agents:

```
[SLB] Approval Request #123
=============================

From: agent-42
Operation: database migration: drop users_legacy table
Files: migrations/drop_legacy.sql
Risk: HIGH (destructive operation)

To approve: slb approve 123 --agent <your-id>
To reject: slb reject 123 --reason "..."

Waiting for second agent approval...
```

### 3. Reviewer Validates

Second agent must:
1. Review the operation description
2. Examine affected files
3. Verify the change is correct
4. Approve or reject

```bash
# If approved
slb approve 123 --agent agent-15 --robot --json

# If rejected
slb reject 123 --reason "Migration targets wrong table" --robot --json
```

### 4. Execute or Abort

**On Approval:**
```
[SLB] Request #123 APPROVED
============================
Approved by: agent-15
You may now execute the operation.

Execute: slb execute 123 --robot --json
```

**On Rejection:**
```
[SLB] Request #123 REJECTED
============================
Rejected by: agent-15
Reason: Migration targets wrong table

Operation blocked. Review and resubmit.
```

## Audit Trail

All SLB operations are logged:

```bash
slb audit --robot --json
```

```
SLB Audit Log
=============

#123 | 2024-01-20 14:30 | APPROVED
  Op: database migration
  By: agent-42
  Approved: agent-15
  Executed: 14:32

#122 | 2024-01-20 12:15 | REJECTED
  Op: force push main
  By: agent-38
  Rejected: agent-42
  Reason: "Contains uncommitted debug code"

#121 | 2024-01-19 16:45 | APPROVED
  Op: security config change
  By: agent-15
  Approved: agent-42
  Executed: 16:48
```

## Integration with DCG

DCG (Destructive Command Guard) automatically triggers SLB for dangerous commands:

```bash
# Attempting dangerous operation
git push --force origin main

# DCG intercepts:
[DCG] Command blocked: git push --force
This operation requires two-person approval.

Creating SLB request...
[SLB] Request #124 created
Waiting for approval from another agent.
```

## Commands Protected by Default

- `git push --force`
- `git reset --hard`
- `git clean -fd`
- `rm -rf` on important paths
- `DROP TABLE`, `DROP DATABASE`
- `TRUNCATE TABLE`
- Production deployment commands

## Custom Protection Rules

Configure in `.acfs/slb-rules.yaml`:

```yaml
rules:
  - pattern: "deploy.*production"
    risk: HIGH
    requires_approval: true

  - pattern: "migrate.*down"
    risk: HIGH
    requires_approval: true

  - files:
      - "src/auth/**"
      - "src/security/**"
    risk: MEDIUM
    requires_approval: true
```

## Best Practices

1. **Don't bypass**: Even if you can, don't skip verification
2. **Review thoroughly**: Second agent must actually review
3. **Document reasoning**: Approval should include "why"
4. **Report suspicious**: Flag requests that seem wrong
5. **Maintain audit**: Audit logs are for compliance, preserve them
