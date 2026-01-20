---
name: pre-commit-validation
description: Implements pre-commit validation using UBS bug scanner. Use before committing changes to catch issues early.
---

# Pre-Commit Validation

Validate code quality before every commit using UBS (Ultimate Bug Scanner) and other checks.

## Validation Pipeline

Run before any commit:

```
1. UBS Scan (security/bugs)
2. Tests (functionality)
3. Lint (code style)
4. Type Check (if applicable)
```

## UBS Bug Scanner

### Quick Scan (Recommended)

```bash
ubs scan --staged --robot --json
```

Scans only staged changes. Fast (~1 second for typical changes).

### Full Scan

```bash
ubs scan --all --robot --json
```

Scans entire project. Use for periodic audits.

### Scan Specific Files

```bash
ubs scan --files "file1.ts,file2.ts" --robot --json
```

## Understanding Results

### Severity Levels

| Severity | Action | Example |
|----------|--------|---------|
| CRITICAL | Must fix | SQL injection, auth bypass |
| HIGH | Should fix | XSS, missing input validation |
| MEDIUM | Consider fixing | Potential null reference |
| LOW | Informational | Code smell, minor issues |

### Sample Output

```json
{
  "findings": [
    {
      "severity": "CRITICAL",
      "category": "security",
      "file": "src/api/handler.ts",
      "line": 42,
      "message": "SQL injection - user input concatenated into query",
      "fix": "Use parameterized query: db.query('SELECT * FROM users WHERE id = $1', [userId])"
    }
  ],
  "summary": {
    "critical": 1,
    "high": 0,
    "medium": 2,
    "low": 1
  },
  "status": "BLOCKED"
}
```

## Decision Matrix

| Findings | Action |
|----------|--------|
| CRITICAL > 0 | Block commit, must fix |
| HIGH > 0 | Recommend fix, can override |
| MEDIUM only | Review, proceed if acceptable |
| LOW only | Proceed |
| Clean | Proceed |

## Issue Categories

UBS detects:

### Security
- SQL/NoSQL injection
- XSS (Cross-Site Scripting)
- CSRF vulnerabilities
- Authentication flaws
- Authorization bypass
- Sensitive data exposure
- Insecure cryptography

### Reliability
- Null/undefined dereference
- Unhandled promise rejections
- Memory leaks
- Race conditions
- Resource exhaustion

### Code Quality
- Async/await issues
- Error handling gaps
- Type mismatches
- Dead code

## Integration with Workflow

### Before Manual Commit

```bash
# Always scan before committing
ubs scan --staged

# If clean
git commit -m "feat: ..."

# If issues found
# Fix issues first, then commit
```

### Automated via /acfs:complete

The `/acfs:complete` command includes UBS scan automatically:

```
Quality Gates:
  [PASS] Tests - 42 passed
  [PASS] Build - completed
  [FAIL] UBS Scan - 1 critical issue
    → src/api/handler.ts:42 - SQL injection

Fix required before completion.
```

## False Positives

If UBS reports a false positive:

1. Verify it's truly false positive
2. Add to `.ubsignore` if legitimate:
   ```
   # .ubsignore
   src/legacy/old-code.ts:42  # Known limitation, scheduled for refactor
   ```
3. Document why it's ignored

## Best Practices

1. **Scan frequently**: Run after every significant change
2. **Fix immediately**: Address issues when found, not later
3. **Don't ignore CRITICAL**: Never commit with critical issues
4. **Review HIGH**: Understand why flagged, fix if valid
5. **Track patterns**: If same issues recur, fix root cause
