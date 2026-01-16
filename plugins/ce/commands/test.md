---
description: Run tests and analyze failures
argument-hint: "[test-command]"
allowed-tools: Task
---

**DELEGATION ONLY**: Do NOT run any commands or investigate the codebase yourself. Your only job is to immediately invoke the `ce:haiku` agent via Task tool, passing the prompt template below with `$ARGUMENTS` substituted.

## Task Prompt for Haiku Agent

```
Run tests and analyze any failures.

User arguments: $ARGUMENTS
(If provided, use as the test command. Otherwise, auto-detect.)

**Step 1: Detect the test command** (if no custom command provided)
- Check for pubspec.yaml → `flutter test` (or `dart test` for pure Dart)
- Check for integration_test/ directory → `flutter test integration_test/`
- Check for package.json → `npm test` or `yarn test`
- Check for firebase.json with functions → `cd functions && npm test`
- Check for Makefile with test target

**Step 2: Run the tests**
Execute the detected or provided test command.

**Step 3: Analyze failures** (if any occur)
- Parse the failure messages
- Identify root causes
- Reference specific file:line locations
- Suggest fixes

**Step 4: Report results**
Provide a summary including:
- Total tests run
- Passed/failed/skipped counts
- For failures: clear, actionable feedback
```
