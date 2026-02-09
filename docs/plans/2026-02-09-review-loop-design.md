# Review Loop Design

> **Status:** DRAFT

## Problem

The executing-plans skill runs `ce:code-reviewer` once and moves on. If the review finds issues, the orchestrator fixes them, but nobody checks whether the fixes introduced new problems. There's also no way to distinguish "auto-fix this obvious bug" from "ask the user about this design tradeoff" from "ignore this pre-existing style issue."

## Solution

Add a review loop to step 4 of `ce:executing-plans`. The code-reviewer agent produces structured JSON findings. The orchestrator filters by relevance and confidence, auto-fixes what's safe, asks the user about ambiguous items in a single batch, and re-runs until clean or 3 iterations.

## Architecture

```
Orchestrator (executing-plans)              ce:code-reviewer agent
     |                                              |
     +--- dispatch review --------------------------->
     |                                              +-- analyze diff
     |                                              +-- classify findings
     |    <-- json:review-findings -----------------+
     |
     +--- parse findings
     +--- relevance filter (is this about our plan?)
     +--- confidence filter (safe to auto-fix?)
     |
     +--- auto-fix: dispatch fix agent
     +--- ask user: batch into AskUserQuestion
     +--- skip: log to summary
     |
     +--- re-dispatch review (scoped to fix-agent changes only)
     |    ... repeat until clean or 3 iterations
     |
     +--- done
```

**Separation of concerns:** The agent is the classification expert (severity, confidence, fix type). The orchestrator is the decision-maker (what to fix, what to ask about, what to skip). Neither crosses into the other's domain.

## Agent Output Format

The code-reviewer agent produces structured JSON instead of freeform markdown. The orchestrator renders human-readable output from the structured data. This avoids dual-output inconsistency (the biggest reliability risk the SME reviewers flagged).

````
```json:review-findings
{
  "summary": {
    "files_changed": 4,
    "lines_added": 120,
    "lines_removed": 35,
    "change_type": "feature",
    "scope": "Add email validation to login flow"
  },
  "findings": [
    {
      "finding": "Missing null check on user input",
      "severity": "critical",
      "file": "src/auth/login.ts",
      "line": 45,
      "rationale": "user.email is accessed but user can be null when session expires, causing TypeError.",
      "fix": "Add `if (!user?.email) throw new ValidationError('Email required')` before line 47",
      "fix_type": "inline",
      "issue_confidence": "high",
      "fix_confidence": "high"
    },
    {
      "finding": "No test for error path",
      "severity": "important",
      "file": "src/auth/login.ts",
      "line": 67,
      "rationale": "The validation logic added in this plan has no test for invalid credentials.",
      "fix": "Add test case in tests/auth/login.test.ts for invalid email input",
      "fix_type": "localized",
      "issue_confidence": "high",
      "fix_confidence": "medium"
    },
    {
      "finding": "Function name doesn't match convention",
      "severity": "suggestion",
      "file": "src/auth/login.ts",
      "line": 12,
      "rationale": "Codebase uses handleX for event handlers. doLogin breaks this pattern.",
      "fix": "Rename doLogin to handleLogin across this file",
      "fix_type": "localized",
      "issue_confidence": "medium",
      "fix_confidence": "high"
    }
  ],
  "verdict": {
    "decision": "request_changes",
    "reason": "Critical null safety issue must be fixed before merge"
  }
}
```
````

### Field Definitions

| Field | Values | Purpose |
|-------|--------|---------|
| `severity` | `critical`, `important`, `suggestion` | How bad is the problem |
| `issue_confidence` | `high`, `medium`, `low` | How certain this is actually a problem |
| `fix_confidence` | `high`, `medium`, `low` | How certain the suggested fix is correct and safe |
| `fix_type` | `inline`, `localized`, `cross-file` | Scope of the fix |
| `rationale` | Free text | Why this matters (orchestrator renders this for humans) |

### Confidence Calibration Rules

The agent prompt must include concrete anchors to prevent systematic overconfidence:

**issue_confidence:**
- `high`: Deterministic issue. Accessing `.length` on a possibly-null value, missing `await` on a Promise, unreachable code after a return. You can see the bug without knowing the runtime context.
- `medium`: Likely real but depends on runtime context you can't fully verify. Race conditions, state mutations from other modules, behavior under load.
- `low`: Speculative. "This might cause performance problems at scale." Or requires understanding business logic not visible in the diff.

**fix_confidence:**
- `high`: Single-line change with no side effects. The fix is self-contained and can't break anything else.
- `medium`: Fix is probably correct but touches a code path you can't fully trace, or requires changes in more than one location within the file.
- `low`: Fix requires understanding code outside the diff, changing public interfaces, or architectural judgment.

Anti-overconfidence instruction: "Err toward medium when uncertain. If you can't see the full call chain or don't know how a value is used downstream, confidence is medium at most. A finding that requires understanding code outside the diff is never high confidence."

## Orchestrator Loop

### Decision Matrix

The orchestrator only auto-fixes findings that are relevant to this plan AND safe to change automatically:

| Relevant? | fix_type | fix_confidence | Action |
|-----------|----------|----------------|--------|
| Yes | `inline` | `high` | Auto-fix |
| Yes | `inline` | `medium` | Ask user |
| Yes | `localized` | `high` | Ask user |
| Yes | `localized`/`cross-file` | any | Ask user |
| Yes | any | `low` | Skip, log to summary |
| No | any | any | Skip, log to summary |

The key constraint: **only auto-fix what's certainly relevant and an improvement for the given task.** `inline` + `high fix_confidence` is the only combination that qualifies. Everything else gets human eyes.

### Relevance Filter

A finding is relevant to this plan if the code it flags was touched by this plan's work.

**Check order (first match wins):**

1. **File match.** Is the finding's file in the plan's changed files? Check `git diff --name-status` and account for renames (`R` entries). If the file isn't in the plan's changes, skip.
2. **Line match.** Is the finding on a line added or modified in this plan's diff? If yes, relevant.
3. **Proximity halo.** Is the finding within +/- 15 lines of a changed line in the same file? If yes, relevant. (This replaces "same function" detection, which would require AST parsing we don't have.)
4. **Not matched.** Finding is on an unchanged line far from any changes. Skip.

**What's NOT relevant (even if in a changed file):**
- Pre-existing style issues on untouched lines outside the 15-line halo
- Suggestions to refactor adjacent code the plan didn't modify
- Findings about test files the plan didn't create or change

### Loop Algorithm

```
iteration = 0
skipped = []
user_resolved = []
review_scope = "full"  // first pass reviews all plan changes

while iteration < 3:
    iteration++
    findings = dispatch ce:code-reviewer(scope=review_scope)

    parse json:review-findings block
    new_actionable = []

    for each finding:
        if finding in user_resolved → skip
        if not relevant(finding) → skipped.append(finding)
        else → new_actionable.append(finding)

    if new_actionable is empty → CLEAN, break

    // convergence check: same findings as last iteration = exit
    if new_actionable == previous_actionable → break

    auto_fix = [f for f in new_actionable
                if f.fix_type == "inline" and f.fix_confidence == "high"]
    ask_user = [f for f in new_actionable if f not in auto_fix and f.issue_confidence != "low"]

    if auto_fix is not empty:
        // batch same-file fixes into one agent
        group fixes by file
        for each file_group:
            dispatch fix agent with all findings for that file
        // lightweight verification before re-review
        run tests on changed files

    if ask_user is not empty:
        batch into one AskUserQuestion:
            "The reviewer flagged these items. For each:"
            options: "Fix" / "Skip (not relevant)" / "Defer to follow-up"
        for user-chosen fixes → dispatch fix agent (same batching rules)
        for skips/defers → user_resolved.append(finding)

    previous_actionable = new_actionable
    review_scope = "files modified by fix agents only"  // narrow subsequent reviews

if iteration == 3 AND still has findings:
    present remaining findings to user:
    "These issues persisted after 3 review cycles. Fix manually or ship as-is?"
```

### Key Behaviors

- **Conservative auto-fix.** Only `inline` + `high fix_confidence` + plan-relevant. The orchestrator doesn't touch anything it isn't sure about.
- **Batch user questions.** All ambiguous findings go into one `AskUserQuestion` with per-finding options. No chatty per-finding questions.
- **Findings don't resurface.** Items the user already skipped/deferred are tracked in `user_resolved` and filtered in subsequent iterations.
- **Convergence exit.** If the same findings appear in consecutive iterations, the loop stops. No point re-reviewing what can't be auto-fixed.
- **Scoped re-reviews.** After iteration 1, only review files the fix agents touched. This controls token cost and prevents discovering new pre-existing issues.
- **Same-file batching.** Multiple fixes in one file go to a single fix agent to avoid conflicts.
- **Test before re-review.** Run tests on fix-agent changes before dispatching the next review iteration. Don't waste a review cycle on broken fixes.

## Files to Change

| File | Action | What |
|------|--------|------|
| `plugins/ce/agents/code-reviewer.md` | Modify | Add structured JSON output section with confidence calibration, fix_type field, and worked example. Replace freeform markdown template with JSON spec. |
| `plugins/ce/skills/executing-plans/SKILL.md` | Modify | Replace single-line review instruction in step 4 with concise summary + link to reference. ~30 words added. |
| `plugins/ce/skills/executing-plans/references/review-loop.md` | Create | Full loop algorithm, relevance filter, decision matrix, AskUserQuestion format, iteration limits, convergence rules. |

**Not changed:**
- `marketplace.json`: Skills directory already declared, no new entries.
- `commands/review.md`: The `/ce:review` command dispatches the code-reviewer agent. It gets the structured JSON output too, which is fine (JSON is still readable). No changes needed.
- `CLAUDE.md`: Internal execution detail, not an architectural concept that needs project-level documentation.

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Structured-only JSON (no dual output) | Dual markdown + structured block is unreliable. Models produce inconsistent findings between blocks and tend to omit the structured section on long reviews. Single canonical format eliminates this. |
| Split confidence into issue + fix | "Am I sure this is a bug?" and "am I sure this fix is safe?" are different questions. Auto-fix needs high fix_confidence specifically. |
| `fix_type` field controls auto-fix boundary | Only `inline` fixes get auto-fixed. `localized` and `cross-file` always need human judgment, regardless of confidence. |
| +/- 15 line halo instead of "same function" | Function boundary detection requires AST parsing that varies by language. Line proximity is simple, language-agnostic, and good enough. |
| Scoped re-reviews after iteration 1 | Full re-review on each iteration is expensive and discovers new pre-existing issues that aren't relevant. Narrowing to fix-agent files keeps the loop focused. |
| 3 iteration max with convergence exit | Prevents infinite loops on subjective findings. Convergence check prevents wasting iterations when no progress is being made. |
| Reference file in `skills/executing-plans/references/` | Skills own their references. The `commands/references/` directory is for command-level references (like `expert-generation.md` for `init.md`). |

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Reviewer produces malformed JSON | Fallback: regex extraction of individual finding objects. If that fails too, treat as "review passed" and log warning. Don't block the plan on a parse failure. |
| All findings are low confidence | Loop exits immediately (nothing actionable). Log findings to summary. |
| Fix agent introduces new bug | Next review iteration catches it. If the same fix fails twice, stop and ask user. |
| Renamed files in plan | Relevance filter checks `git diff --name-status` for `R` entries and maps old names to new names. |
| Plan creates entirely new files | New files are always relevant (they're 100% this plan's work). |
| User skips all findings | `user_resolved` tracks them, loop exits clean on next iteration. |
| Zero findings on first review | Loop exits immediately. No overhead. |
