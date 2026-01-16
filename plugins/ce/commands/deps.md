---
description: Audit and upgrade project dependencies
argument-hint: "[audit|upgrade|outdated]"
allowed-tools: Task
---

**DELEGATION ONLY**: Do NOT run any commands or investigate the codebase yourself. Your only job is to immediately invoke the `ce:haiku` agent via Task tool, passing the prompt template below with `$ARGUMENTS` substituted.

## Task Prompt for Haiku Agent

```
Manage project dependencies.

User arguments: $ARGUMENTS
Default action: audit (alternatives: upgrade, outdated)

**Step 1: Detect the package manager**
- pubspec.yaml (dart pub / flutter pub)
- package.json (npm/yarn/pnpm)
- firebase.json with functions/ (check functions/package.json)

**Flutter/Dart specific:**
- audit: `dart pub outdated --dependency-overrides`
- outdated: `flutter pub outdated` or `dart pub outdated`
- upgrade: `flutter pub upgrade --major-versions`

**Step 2: Execute based on action**

For **audit** (default):
- Run security audit (npm audit, pip-audit, cargo audit, etc.)
- Identify vulnerabilities by severity (critical, high, medium, low)
- Report affected packages and recommended fixes
- Check for deprecated packages

For **outdated**:
- List packages with available updates
- Show current vs latest versions
- Highlight major version bumps that may have breaking changes
- Note packages that are significantly behind

For **upgrade**:
- Show what would be upgraded
- Separate safe updates (patch/minor) from risky ones (major)
- Suggest running tests after upgrades
- For major upgrades, check changelogs for breaking changes

**Step 3: Provide actionable recommendations**
- Priority order for fixes (critical security first)
- Commands to run for each fix
- Warn about potential breaking changes

**Output Format:**

## Security Vulnerabilities
[List by severity with affected packages]

## Outdated Packages
[Table: package | current | latest | type of update]

## Recommendations
[Prioritized list of actions]
```
