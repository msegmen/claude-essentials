# Review Loop Algorithm (Step 4)

The review loop is the verification backbone of `ce:executing-plans` step 4. It dispatches `ce:code-reviewer` to produce structured JSON findings, filters by relevance and confidence, auto-fixes what's safe, batches ambiguous items into a single user question, and re-runs until clean or 3 iterations. The orchestrator decides what to fix; the reviewer classifies. Neither crosses into the other's domain.

## Decision matrix

The orchestrator only auto-fixes findings that are relevant to this plan AND safe to change automatically.

| Relevant? | fix_type | fix_confidence | Action |
|-----------|----------|----------------|--------|
| Yes | `inline` | `high` | Auto-fix |
| Yes | `inline` | `medium` | Ask user |
| Yes | `localized` | `high` | Ask user |
| Yes | `localized` / `cross-file` | `medium` or `high` | Ask user |
| Yes | any | `low` | Skip, log to summary |
| No | any | any | Skip, log to summary |

The key constraint: **only `inline` + `high fix_confidence` + relevant qualifies for auto-fix.** Everything else gets human eyes or gets skipped.

## Relevance filter

A finding is relevant if the code it flags was touched by this plan. Check in order (first match wins):

| Check | Rule | Result |
|-------|------|--------|
| **File match** | Is the finding's file in the plan's changed files? Check `git diff --name-status` and account for renames (`R` entries map old name to new). | If file not in plan changes, **skip**. |
| **New file** | Was the file created by this plan? | Always **relevant** (100% this plan's work). |
| **Line match** | Is the finding on a line added or modified in the plan's diff? | **Relevant**. |
| **Proximity halo** | Is the finding within +/- 15 lines of any changed line in the same file? | **Relevant**. |
| **No match** | Finding is on an unchanged line outside the halo. | **Skip**. |

**Not relevant (even if in a changed file):**
- Pre-existing style issues on untouched lines outside the 15-line halo
- Suggestions to refactor adjacent code the plan didn't modify
- Findings about test files the plan didn't create or change

## Loop algorithm

```
iteration = 0
skipped = []
user_resolved = []
previous_actionable = []
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
    // compare by file + line + finding title (tolerates LLM rephrasing)
    if new_actionable matches previous_actionable by (file, line, finding) → break

    auto_fix = [f for f in new_actionable
                if f.fix_type == "inline" and f.fix_confidence == "high"]
    ask_user = [f for f in new_actionable
                if f not in auto_fix and f.issue_confidence != "low"]

    // if nothing to fix or ask about, remaining items are low-confidence skips
    if auto_fix is empty AND ask_user is empty:
        skipped.extend(new_actionable)
        break

    if auto_fix is not empty:
        // batch same-file fixes into one agent
        group fixes by file
        for each file_group:
            dispatch fix agent with all findings for that file
        // lightweight verification before re-review
        run tests on changed files

    if ask_user is not empty:
        batch into one AskUserQuestion (see format below)
        for user-chosen fixes → dispatch fix agent (same batching rules)
        for skips/defers → user_resolved.append(finding)

    previous_actionable = new_actionable
    review_scope = "files modified by fix agents only"  // narrow subsequent reviews

if iteration == 3 AND still has findings:
    present remaining findings to user:
    "These issues persisted after 3 review cycles. Fix manually or ship as-is?"
```

**Key behaviors:**

- **Same-file batching.** Multiple fixes in one file go to a single fix agent to avoid conflicts.
- **Scoped re-reviews.** After iteration 1, only review files the fix agents touched. Controls token cost and prevents discovering new pre-existing issues.
- **Test before re-review.** Run tests on fix-agent changes before dispatching the next review iteration. Don't waste a review cycle on broken fixes.
- **Findings don't resurface.** Items the user already skipped or deferred are tracked in `user_resolved` and filtered out in subsequent iterations.

## AskUserQuestion format

Batch all ambiguous findings into one `AskUserQuestion`. Don't ask per-finding questions.

```
The reviewer found N issues. X were auto-fixed (inline, high confidence).
The remaining Y need your input:

1. **Missing null check on user input** (src/auth/login.ts:45)
   critical | fix_confidence: medium
   user.email accessed but user can be null when session expires.
   → [Fix] [Skip (not relevant)] [Defer to follow-up]

2. **No test for error path** (src/auth/login.ts:67)
   important | fix_confidence: medium
   Validation logic has no test for invalid credentials.
   → [Fix] [Skip (not relevant)] [Defer to follow-up]

3. **Function name doesn't match convention** (src/auth/login.ts:12)
   suggestion | fix_confidence: high
   Codebase uses handleX; doLogin breaks the pattern.
   → [Fix] [Skip (not relevant)] [Defer to follow-up]
```

Per-finding options:
- **Fix** dispatches a fix agent (same-file batching applies).
- **Skip** marks the finding as not relevant; added to `user_resolved`.
- **Defer to follow-up** logs the finding for post-plan work; added to `user_resolved`.

## Exit conditions

| Condition | When | What happens |
|-----------|------|--------------|
| **Clean** | Zero actionable findings after filtering | Loop exits. Verification passes. |
| **Convergence** | `new_actionable` matches `previous_actionable` | Loop exits. Remaining findings are presented to the user as a final summary. No point re-reviewing what can't be auto-fixed. |
| **Iteration limit** | 3 iterations reached with findings still present | Loop exits. Remaining findings presented: "These issues persisted after 3 review cycles. Fix manually or ship as-is?" |
| **Zero findings first pass** | Reviewer returns no findings on iteration 1 | Loop exits immediately. No overhead. |

## Edge cases

| Scenario | Handling |
|----------|----------|
| Malformed JSON from reviewer | Regex-extract individual finding objects. If that fails too, treat as "review passed" and log warning. Don't block the plan on a parse failure. |
| All findings are low confidence | Nothing actionable (filtered out by `issue_confidence != "low"` check). Loop exits immediately. Log findings to summary. |
| Fix agent introduces new bug | Next review iteration catches it. If the same fix fails twice, stop and ask user. |
| Renamed files in plan | Relevance filter checks `git diff --name-status` for `R` entries and maps old names to new names before file matching. |
| Plan creates entirely new files | New files are always relevant. They're 100% this plan's work. |
| User skips all findings | All findings added to `user_resolved`. Next iteration filters them out, finds nothing actionable, exits clean. |
| Reviewer returns empty findings array | Same as zero findings. Loop exits clean. |
| Same finding on boundary of two changed regions | Proximity halo covers it. One match is enough for relevance. |
