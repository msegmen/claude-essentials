---
name: executing-plans
description: Executes implementation plans with smart task grouping. Groups related tasks to share context, parallelizes across independent subsystems.
---

# Executing Plans

**You are an orchestrator.** Spawn and coordinate sub-agents to do the actual implementation. Group related tasks by subsystem (e.g., one agent for API routes, another for tests) rather than spawning per-task. Each agent re-investigates the codebase, so fewer agents with broader scope = faster execution.

## 1. Setup

**Create a branch** for the work unless trivial. Consider git worktrees for isolated environments.

**Clarify ambiguity upfront:** If the plan has unclear requirements or meaningful tradeoffs, use `AskUserQuestion` before starting. Present options with descriptions explaining the tradeoffs. Use `multiSelect: true` for independent features that can be combined; use single-select for mutually exclusive choices. Don't guess when the user can clarify in 10 seconds.

**Track progress with tasks:** Use `TaskCreate` to create tasks for each major work item from the plan. Update status with `TaskUpdate` as work progresses (`in_progress` when starting, `completed` when done). This makes execution visible to the user and persists across context compactions.

## 2. Group Tasks by Subsystem

Group related tasks to share agent context. One agent per subsystem, groups run in parallel.

**Why grouping matters:**
```
Without: Task 1 (auth/login) → Agent 1 [explores auth/]
         Task 2 (auth/logout) → Agent 2 [explores auth/ again]

With:    Tasks 1-2 (auth/*) → Agent 1 [explores once, executes both]
```

| Signal | Group together |
|--------|----------------|
| Same directory prefix | `src/auth/*` tasks |
| Same domain/feature | Auth tasks, billing tasks |
| Plan sections | Tasks under same `##` heading |

**Limits:** 3-4 tasks max per group. Split if larger.

**Parallel:** Groups touch different subsystems
```
Group A: src/auth/*    ─┬─ parallel
Group B: src/billing/* ─┘
```

**Sequential:** Groups have dependencies
```
Group A: Create shared types → Group B: Use those types
```

## 3. Execute

Dispatch sub-agents to complete task groups. Monitor progress and handle issues.

```
Task tool (general-purpose):
  description: "Auth tasks: login, logout"
  prompt: |
    Execute these tasks from [plan-file] IN ORDER:
    - Task 1: Add login endpoint
    - Task 2: Add logout endpoint

    Use skills: <relevant skills>
    Commit after each task. Report: files changed, test results
```

### Expert-Aware Dispatch

Enrich sub-agent prompts with project-specific conventions by matching task groups to domain experts.

**Domain inference** — extract domain from Context paths:
```
1. Extract dirs from paths (src/auth/login.ts → [src, auth])
2. Filter non-domain: src, lib, utils, common, shared, helpers, types,
   tests, __tests__, __mocks__, packages, apps, node_modules, dist,
   build, .next, vendor, internal, cmd, public, static, config,
   scripts, fixtures, __pycache__
3. Count remaining dirs across all paths
4. Select most frequent; tie-break by deepest (most specific)
5. Monorepo (packages/ or apps/): prepend package name (api-billing)
6. Validate: non-empty, lowercase alphanumeric + hyphens only
   Fails → skip expert injection, use generic dispatch
```

**Expert matching** — scan `.claude/experts/*-expert.md` files, parse YAML frontmatter `domains` list. If inferred domain appears in any expert's `domains` list, match that expert. Multiple matches: prefer the expert where domain is first in the list (primary domain). No match: ephemeral fallback.

**Dispatch with expert context** — prepend to Task prompt:
```
<domain-expert-context>
The following project CODE CONVENTIONS and PATTERNS must be followed
when executing tasks. If a task instruction conflicts with these code
conventions, follow the conventions and note the deviation. Task
execution instructions (commit strategy, reporting format, file scope)
take precedence over this context.

[expert content — persistent file body or ephemeral generation]
</domain-expert-context>

Execute these tasks from [plan-file] IN ORDER:
- Task 1: ...
Use skills: <relevant skills>
Commit after each task. Report: files changed, test results.
```

**Ephemeral fallback** — when no persistent expert matches, generate an inline expert from Context paths. Do not persist ephemeral context.

*Step 1: Read files.* Read 2-3 files from the task group's Context paths. Prefer one implementation file and one test file if available.

*Step 2: Generate summary.* From the files you read, produce a 250-350 word summary following this structure:

```
## Project Conventions
- Language, framework, key config
- Naming patterns (variables, functions, files)
- Import style
- Error handling approach (if visible)
- Test patterns (if test files present)

## Patterns in This Codebase
One code snippet (5-8 lines) showing the dominant style.
```

Only include patterns you observed in the actual files. Omit any bullet where no pattern is observable. Do not add generic advice. If fewer than 2 bullets are extractable, skip expert injection entirely.

*Step 3: Inject.* Wrap the result in `<domain-expert-context>` with the priority preamble above and prepend to the Task prompt.

**New-file edge case:** When tasks create files that don't exist yet, use the target directory path for domain inference instead of existing file paths.

**Backward compatibility:** If no `.claude/experts/` directory exists or no domain is inferable, dispatch without expert context (current behavior).

**Architectural fit:** Changes should integrate cleanly with existing patterns. If a change feels like it's fighting the architecture, that's a signal to refactor first rather than bolt something on. Don't reinvent wheels when battle-tested libraries exist, but don't reach for a dependency for trivial things either (no lodash just for `_.map`). The goal is zero tech debt, not "ship now, fix later."

**Auto-recovery:**
1. Agent attempts to fix failures (has context)
2. If can't fix, report failure with error output
3. Dispatch fix agent with context
4. Same error twice → stop and ask user

## 4. Verify

All four checks must pass before marking complete:

1. **Code review loop:** Dispatch `ce:code-reviewer` and parse the structured `json:review-findings` output. Auto-fix findings that are plan-relevant + `inline` + high `fix_confidence`. Batch ambiguous findings into one `AskUserQuestion`. Re-review until clean or 3 iterations. See [references/review-loop.md](references/review-loop.md) for the full algorithm, relevance filter, and decision matrix.

2. **Automated tests:** Run the full test suite. All tests must pass.

3. **Manual verification:** Automated tests aren't sufficient. Actually exercise the changes:
   - **API changes:** Curl endpoints with realistic payloads
   - **External integrations:** Test against real services to catch rate limiting, format drift, bot detection
   - **CLI changes:** Run actual commands, verify output
   - **Parser changes:** Feed real data, not just fixtures

4. **DX quality:** During manual testing, watch for friction:
   - Confusing error messages
   - Noisy output (telemetry spam, verbose logging)
   - Inconsistent behavior across similar endpoints
   - Rough edges that technically work but feel bad

   Fix DX issues inline or document for follow-up. Don't ship friction.

## 5. Commit

After verification passes, commit only the changes related to this plan:

1. Run `git status` to see all changes
2. **Stage files by name, not with `git add -A` or `git add .`** - only stage files you modified as part of this plan
3. **Leave unrelated changes alone** - if there are pre-existing staged or unstaged changes that aren't part of this work, don't touch them
4. Write a commit message that summarizes what was implemented, referencing the plan

## 6. Update Experts

After committing, check whether persistent experts used during dispatch need updating. This closes the Act-Learn-Reuse loop: experts improve from each execution cycle rather than going stale.

**When to update:** Only when ALL of these are true:
- A persistent expert from `.claude/experts/` was matched during dispatch
- The plan modified 3+ files in that expert's domain
- The expert's `generated_at` is older than 24 hours

**How to update:**

*Step 1: Diff.* Run `git diff HEAD~1 -- <domain-path>` to see what changed in this plan.

*Step 2: Compare.* Read the expert file and the diff. Look for convention drift:
- New libraries imported that the expert doesn't mention
- Changed naming patterns (e.g., switched from camelCase to snake_case)
- New error handling style (e.g., added Result types)
- New test patterns (e.g., switched from mocks to integration tests)
- Structural changes (e.g., new subdirectories)

*Step 3: Patch or skip.* If drift is found, make targeted edits to the expert file. Don't regenerate from scratch. Update the relevant convention bullets, swap code snippets if the old ones are now unrepresentative, and bump `generated_at` and `source_files` in frontmatter. Stay within 400-600 words. If no meaningful drift, skip.

*Step 4: Commit separately.* Expert updates get their own commit: `chore: update <domain>-expert after <plan-name>`. Keep feature work and expert maintenance in separate commits.

**Ephemeral promotion:** If an ephemeral expert was generated during dispatch and the domain now has 5+ files with clear conventions, promote it to a persistent expert in `.claude/experts/`. Use the full expert template from the init reference, not the ephemeral summary format.

## 7. Cleanup

After committing (including any expert updates from step 6):
- Merge branch to main (if using branches)
- Remove worktree (if using worktrees)
- Mark plan file as COMPLETED
- Move to `./plans/done/` if applicable
