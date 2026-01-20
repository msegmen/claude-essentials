---
description: Run UBS bug scanner on code changes
argument-hint: "[--staged] [--all] [<files>]"
allowed-tools: Bash, Read
---

Pre-commit validation using the Ultimate Bug Scanner (UBS).

## Arguments

Parse `$ARGUMENTS` for:
- `--staged`: Scan only staged changes (default)
- `--all`: Full project scan (slower)
- `<files>`: Specific files to scan

## Workflow

### 1. Determine Scope

- Default: Scan staged files (`git diff --cached --name-only`)
- `--all`: Scan entire project
- `<files>`: Scan specified files only

### 2. Run UBS

```bash
# Staged changes (fast, recommended)
ubs scan --staged --robot --json

# Full project (slower)
ubs scan --all --robot --json

# Specific files
ubs scan --files "file1.ts,file2.ts" --robot --json
```

### 3. Parse Results

UBS returns findings by severity:
- **CRITICAL**: Must fix before commit
- **HIGH**: Should fix before commit
- **MEDIUM**: Consider fixing
- **LOW**: Informational

### 4. Display Results

```
UBS Scan Results
================

Scope: 3 staged files
Duration: 0.8s

CRITICAL (1):
  src/auth/login.ts:42
  SQL Injection vulnerability - user input not sanitized
  Fix: Use parameterized query

HIGH (2):
  src/api/handler.ts:15
  Missing error handling in async function
  Fix: Add try-catch block

  src/auth/token.ts:88
  Token stored in localStorage (XSS risk)
  Fix: Use httpOnly cookie or secure storage

MEDIUM (1):
  src/utils/parse.ts:23
  Potential null dereference
  Fix: Add null check

Summary: 1 critical, 2 high, 1 medium
Status: BLOCKED - Fix critical issues before commit
```

### 5. Recommend Actions

Based on results:
- **CRITICAL found**: Block commit, must fix
- **HIGH found**: Strongly recommend fixing
- **MEDIUM/LOW only**: Can proceed with acknowledgment

## Exit Codes

- `0`: No critical/high issues - safe to commit
- `1`: Issues found - review needed
- `2`: Scan error

## Quick Patterns

```bash
# Before commit (recommended)
/acfs:scan --staged

# Full project audit
/acfs:scan --all

# Specific suspicious file
/acfs:scan src/auth/legacy.ts
```

## Integration with Complete

`/acfs:complete` automatically runs `/acfs:scan --staged` as part of quality gates.

## Issue Categories

UBS detects:
- SQL/NoSQL injection
- XSS vulnerabilities
- CSRF risks
- Authentication issues
- Authorization flaws
- Sensitive data exposure
- Null/undefined handling
- Async/await issues
- Memory leaks
- Race conditions
