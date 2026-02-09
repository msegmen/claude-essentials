# Two-Tier Domain Expert System Design

> **Status:** COMPLETED (v3)

## Specification

**Goal:** Add a two-tier domain expert system to the plan→execute pipeline. Common experts are generated during `/ce:init` by scanning the codebase broadly and persist across all plans. Specialized experts are generated ephemerally during `ce:executing-plans` for plan-specific domains not covered by common experts. Both tiers inject project-specific system prompts into subagent dispatches to replace generic general-purpose execution with domain-aware execution.

**Success Criteria:**

- [ ] `/ce:init` generates common expert files by scanning codebase structure
- [ ] Expert prompts include project-specific conventions extracted from actual code
- [ ] Common experts persist in `.claude/experts/` for reuse across plans
- [ ] `ce:executing-plans` matches task groups to common experts via domain frontmatter
- [ ] Task groups with no matching common expert get ephemeral expert context generated on-the-fly
- [ ] Plans without any expert infrastructure execute normally (backward compatible)
- [ ] Verify marketplace.json needs no changes (existing file modifications only)

## Architecture Overview

```
Tier 1: Common Experts (persistent)
──────────────────────────────────────
/ce:init (one-time or periodic)
     ↓  Detect stack (existing Step 1)
     ↓  Read project metadata (existing Step 2)
     ↓  NEW: Scan codebase domains → identify major areas
     ↓  NEW: Read representative files per domain → extract conventions
     ↓  NEW: Generate common experts to .claude/experts/
     ↓  Build generation plan (existing Step 3)
     ↓  ...rest of init unchanged...

Tier 2: Specialized Experts (ephemeral)
──────────────────────────────────────
/ce:plan → writes plan file (unchanged)
     ↓
/ce:execute
     ↓  For each task group:
     ├─ Check .claude/experts/ for domain match (via frontmatter)
     ├─ Match found → inject persistent expert context
     └─ No match → read task Context files → generate ephemeral
        expert summary inline → inject into Task prompt
```

**Why two tiers:**
- Common experts cover 80% of domains (the technology stack you use every day). Generating these once is cheaper than regenerating per-plan.
- Specialized experts cover the 20% that is plan-specific (a new integration, a migration target, a domain the project hasn't touched before). These are ephemeral because they may never be needed again.

---

## Tier 1: Common Experts via `/ce:init`

### Integration Point

Add a new **Step 2.5** between "Read Project Metadata" (Step 2) and "Build Generation Plan" (Step 3) in the Fresh Init Mode. Extract detailed logic to `commands/references/expert-generation.md` to keep `init.md` under the 500-line guidance.

In Audit Mode, add a check for missing or stale experts.

### Step 2.5: Generate Common Domain Experts

#### 2.5a: Identify Major Domains

Scan the project structure to find the major technology domains:

```
Scan: Top-level src/ or equivalent, 2 levels deep
Identify: Directories with 3+ files that represent distinct domains
```

**Domain detection heuristics (in priority order):**

| Signal | Domain | Example |
|--------|--------|---------|
| Directory name under src/ | Named domain | `src/auth/` → `auth` |
| Framework-specific directories | Framework domain | `app/api/` → `api`, `components/` → `frontend` |
| Test directories with domain mirrors | Confirms domain | `tests/auth/` confirms `auth` |
| Package directories in monorepos | Scoped domain | `packages/api/` → `api` |

**Rules:**
- Shared directories (`utils/`, `lib/`, `common/`, `shared/`) are **never** a domain — they are dependencies
- In monorepos, include the package name in domain: `api-auth`, `web-auth`
- If a domain directory has 15+ files with clear subdirectories, consider subdomain experts
- Maximum 5-6 common experts per project (more = diminishing returns)

#### 2.5b: Extract Conventions Per Domain

For each identified domain, read 3-5 representative files and extract:

| What | How |
|------|-----|
| Language and framework | File extensions, imports, config files |
| Naming conventions | Variable/function/file naming patterns observed |
| Test patterns | Test runner, assertion style, file placement, mock approach |
| Error handling patterns | Try-catch style, Result types, custom error classes, middleware |
| Import conventions | Barrel exports vs direct, path aliases, default vs named |
| Key libraries | Import statements, usage patterns |
| Project structure | Directory layout within the domain |

**Also extract from git (cheap, high-signal):**
```bash
git log --oneline -10  # Commit message format
```

**What NOT to extract:** Generic domain knowledge the model already has. Only project-specific patterns observed in actual files. The generation prompt must instruct: "Only include patterns you observed in the files you read. Do not add generic domain advice."

**Sparse results:** If a domain has fewer than 3 files or no test files, omit the corresponding convention bullets entirely rather than writing "No pattern observed." A shorter, factual expert is better than one padded with empty sections.

#### 2.5c: Write Expert Files

Create `.claude/experts/` directory if it doesn't exist (`mkdir -p`). Write expert files to `.claude/experts/<domain>-expert.md` (NOT `.claude/agents/` — avoids agent auto-discovery confusion).

**Expert prompt template:**

```markdown
---
name: <domain>-expert
domains:
  - <primary-domain-name>
  - <alias-1>
  - <alias-2>
generated_at: <ISO timestamp>
source_files:
  - <file1>
  - <file2>
  - <file3>
---

## Identity

You are a <domain> specialist working in a <language>/<framework> codebase.

## Project Conventions

- **Language:** <language> with <config details>
- **Framework:** <framework>
- **Naming:** <observed naming patterns>
- **Testing:** <test runner>, <assertion style>, tests in <location>
- **Error handling:** <observed error patterns>
- **Imports:** <import conventions>
- **Key libraries:** <libraries and usage patterns>
- **Structure:** <how this domain's code is organized>

## Patterns in This Codebase

<1-2 code snippets of 5-10 lines each showing representative patterns
from actual files read. These anchor the model's style to match the project.>

## Boundaries

- **You handle:** <in-scope, 2-3 items>
- **Out of scope:** If you need <adjacent domain> changes, document them as a follow-up task rather than implementing directly
```

**Key frontmatter field — `domains`:** This list enables robust matching at dispatch time. Include the primary domain name plus common aliases and path variations. Examples:

```yaml
# For an auth expert generated from src/auth/
domains: [auth, authentication, user-auth]

# For a frontend expert generated from src/components/
domains: [frontend, components, ui, web]

# For a monorepo API expert
domains: [api-auth, api-authentication]
```

**Constraints:**
- 400-600 words per expert (tight enough to avoid attention dilution, long enough for code examples)
- Code snippets: 5-10 lines each, showing structure not full implementations
- Metadata tracks provenance for staleness detection
- Boundaries use positive redirections, not bare negations
- No Execution Contract section — execution mechanics (commit strategy, reporting format) belong in the dispatch template, not domain experts

**When to cut content (approaching 600-word ceiling):**
Priority order — cut from bottom first:
1. Second code example (keep one)
2. Boundary details (keep to one sentence)
3. Less-critical convention bullets (keep language, naming, testing)

#### 2.5d: Update Generation Plan Display

Add experts to the init plan display shown to the user:

```
Detected stack: TypeScript + React + Express backend

Will create:
  .claude/
  ├── CLAUDE.md
  ├── settings.json
  ├── rules/
  │   ├── testing.md
  │   ├── error-handling.md
  │   └── ...
  └── experts/                    # NEW
      ├── api-expert.md           # Express API conventions
      ├── frontend-expert.md      # React component patterns
      ├── database-expert.md      # Prisma/SQL patterns
      └── testing-expert.md       # Jest/Vitest patterns
```

**`--force` behavior:** When `/ce:init --force` is used, regenerate all experts without confirmation (matching existing init behavior for other generated files).

### Audit Mode Addition

In Audit Mode Step 2, add checks for:

**Missing experts:**
- Major domains detected in codebase that lack expert files

**Stale experts:**
- Compare `generated_at` timestamp against file modification times of `source_files`
- If source files changed significantly since expert generation, flag for update

**Report format:**
```
Experts:
  + api-expert.md: Up to date
  - frontend-expert.md: Stale (src/components/ modified since generation)
  - Missing: database-expert.md (detected Prisma in src/db/)

Regenerate stale/missing experts? [Y/n]
```

---

## Tier 2: Ephemeral Experts in `ce:executing-plans`

### Integration Point

Add logic to `ce:executing-plans` Section 3 (Execute), in the dispatch step.

### Domain Inference Algorithm

When dispatching a task group, infer domain from Context paths:

```
1. Extract directory components from all Context paths
   - src/auth/login.ts           → [src, auth]
   - packages/api/src/billing/   → [packages, api, src, billing]
   - tests/auth/login.test.ts    → [tests, auth]

2. Filter out non-domain directories:
   src, lib, utils, common, shared, helpers, types, tests,
   packages, apps, node_modules, dist, build

3. Count remaining directories across all Context paths
   - auth: 2 occurrences, billing: 1 occurrence

4. Select domain: most common directory name
   - Tie-break: prefer deepest path (most specific)

5. For monorepos (packages/ or apps/ detected):
   - Prepend package name: api-billing, web-auth

6. Validate:
   - Domain must not be empty
   - Domain must be lowercase alphanumeric with hyphens
   - If validation fails → skip expert injection, use generic dispatch
```

### Expert Matching

Match inferred domain against expert frontmatter, NOT filenames:

```
1. Scan all .claude/experts/*-expert.md files
2. Parse YAML frontmatter, read `domains` list
3. If inferred domain appears in ANY expert's domains list → match
4. If multiple experts match → prefer the one where domain appears first
   in the domains list (primary domain)
5. No match → generate ephemeral expert (Tier 2 fallback)
```

This is more robust than filename matching. `src/authentication/` matches `auth-expert.md` because its `domains` list includes `authentication`.

### Dispatch Logic

For each task group being dispatched:

```
1. Run domain inference algorithm (above)

2. Run expert matching (above)
   ├─ Match found → Read expert file body (below frontmatter)
   │                Wrap in <domain-expert-context> with priority preamble
   │                Prepend to Task prompt
   │
   └─ No match → Generate ephemeral expert:
                  a. Read 2-3 files from task Context paths
                  b. Use ephemeral generation prompt (below)
                  c. Wrap result in <domain-expert-context>
                  d. Prepend to Task prompt (not persisted)

3. Dispatch with subagent_type: "general-purpose" (unchanged)
```

### Injection Format

```
<domain-expert-context>
The following project CODE CONVENTIONS and PATTERNS must be followed
when executing tasks. If a task instruction conflicts with these code
conventions, follow the conventions and note the deviation. Task
execution instructions (commit strategy, reporting format, file scope)
take precedence over this context.

[expert content — either from persistent file or ephemeral generation]
</domain-expert-context>

Execute these tasks from [plan-file] IN ORDER:
- Task 1: ...
- Task 2: ...

Use skills: <relevant skills>
Commit after each task. Report: files changed, test results.
```

**Why this injection pattern works:**
- XML tags are Claude's recommended delimiter format
- Prepending places expert context in the primacy position (strongest attention)
- Priority preamble scoped to code conventions only — execution mechanics in the dispatch template take precedence
- `general-purpose` subagent type is used (unchanged from current behavior)

### Ephemeral Generation Prompt

When no persistent expert matches, the orchestrator uses this prompt to generate inline context:

```
Read the following files and generate a 250-350 word expert context
summary for the "<inferred-domain>" domain. Include ONLY patterns you
observe in the actual code. Do NOT add generic advice.

Structure your output as:

## Project Conventions
- Language, framework, key config
- Naming patterns (variables, functions, files)
- Import style (barrel exports, path aliases, default vs named)
- Error handling approach (if visible)
- Test patterns (if test files present)

## Patterns in This Codebase
One representative code snippet (5-8 lines) showing the dominant style.

Files to read:
- <file1>
- <file2>
- <file3>

Omit any convention bullet where no pattern is observable. A shorter,
factual summary is better than one padded with assumptions.
```

### Ephemeral Expert Budget

Ephemeral experts are shorter than persistent ones (250-350 words vs 400-600) because:
- They skip the Identity and Boundaries sections (less critical for one-off domains)
- They focus only on conventions and patterns
- Generated inline means every extra word costs context in the task execution window

**Context cost accounting:** The orchestrator reads 2-3 files (~100-300 lines each) to generate the ephemeral summary. This is a one-time cost per task group, not per task. For a plan with 5 task groups where 2 need ephemeral experts, the overhead is ~400-600 lines of file reads + ~600-700 words of generated expert context. This is negligible compared to total plan execution time.

---

## File Changes Summary

### New Files

| File | Purpose |
|------|---------|
| `.claude/experts/` directory | Home for persistent common expert files (created by init) |
| `plugins/ce/commands/references/expert-generation.md` | Detailed Step 2.5 logic (extracted from init.md for progressive disclosure) |

### Modified Files

| File | Change |
|------|--------|
| `plugins/ce/commands/init.md` | Add Step 2.5 outline (references expert-generation.md for details). Add expert staleness checks to Audit Mode. |
| `plugins/ce/skills/executing-plans/SKILL.md` | Add expert-aware dispatch logic in Section 3 (~40-50 lines additive) |
| `CLAUDE.md` (project root) | Document `.claude/experts/` convention and two-tier expert system |

### Generated Files (at runtime)

| Location | Lifecycle | Generated By |
|----------|-----------|--------------|
| `.claude/experts/<domain>-expert.md` | Persistent, reusable | `/ce:init` |
| (inline in Task prompt) | Ephemeral, per-dispatch | `ce:executing-plans` |

**Note:** No marketplace.json changes needed — all changes are to existing registered files, and `.claude/experts/` is a runtime output in the target project, not a plugin component.

---

## Design Decisions

### Why `.claude/experts/` not `.claude/agents/`?

Three reasons validated by testing and review:
1. **Agent auto-discovery conflict:** `.claude/agents/` files are discovered by Claude Code as invocable agents. Generated experts lack `tools`/`model`/`color` frontmatter and would confuse users who try to invoke them directly.
2. **Not valid subagent_type targets:** Tested empirically — only plugin-registered agents are valid `subagent_type` values. `.claude/agents/` files are not dispatch targets.
3. **Clean separation:** `.claude/experts/` clearly communicates "these are reference materials for subagent enrichment" not "these are standalone agents."

### Why domain matching via frontmatter, not filenames?

Exact filename matching is brittle. `src/authentication/` won't match `auth-expert.md`. The `domains` list in frontmatter enables canonical domain names with aliases, so a single expert covers path variations like `auth`, `authentication`, `user-auth`. Dispatch scans frontmatter — slightly more expensive than filename lookup but far more robust.

### Why two tiers instead of one?

- **Common experts** cover the stable, recurring domains of a project. Generating them once during init is cheaper than regenerating per-plan, and they can be audited/version-controlled.
- **Ephemeral experts** handle one-off plan-specific domains without file management overhead. No staleness, no naming collisions, no cleanup.
- Together they cover ~100% of task groups with minimal waste.

### Why prompt injection into `general-purpose` not native `subagent_type`?

Tested empirically: only plugin-registered agents (e.g., `ce:code-reviewer`) are valid `subagent_type` targets in the Task tool. Project-level files are not available as dispatch targets. Prompt-enriched `general-purpose` dispatch works immediately without session restart.

### Why 400-600 words for persistent / 250-350 for ephemeral?

Informed by SME review:
- Under 400 words loses the ability to include concrete code examples (critical for style anchoring)
- Over 600 words starts competing with task instructions for model attention (attention dilution in long contexts)
- Ephemeral experts skip structural sections (Identity, Boundaries) since those add less value for one-off domains
- The priority preamble costs ~40 words — accounted for in the budget

### Why no Execution Contract in expert templates?

V2 included an Execution Contract section (~80 words) in expert templates. SME review identified this as redundant with the dispatch template's own execution instructions (commit strategy, reporting format). Worse, the priority preamble created conflict: if the expert's Execution Contract said "commit after each task" but the dispatch said "stage only, don't commit," which wins? The answer should always be the dispatch template for execution mechanics. Removing the Execution Contract frees ~80 words for better code examples and eliminates the conflict surface.

### Why no plan annotation?

The original design proposed annotating plan files with `**Agent:** <name>`. SME review flagged this as a plan file mutation problem (two writers: writing-plans and spawning-experts). The revised design infers domain at dispatch time from Context paths, matching against `.claude/experts/` by frontmatter convention. No plan modification needed.

### Why not a separate `ce:spawning-experts` skill?

SME review identified workflow coupling as the #1 critical issue: users would need to remember to run a separate step between plan and execute. The two-tier approach eliminates this:
- Tier 1 runs during init (already a known step)
- Tier 2 runs automatically inside executing-plans (invisible to user)

### Why scope the priority preamble to code conventions only?

The preamble tells the subagent "follow expert conventions over task instructions." This is correct for code style (naming, patterns, error handling) but wrong for execution mechanics (commit strategy, report format, file scope). An orchestrator may have valid reasons to override execution defaults (e.g., "don't commit, stage only" for a review-before-commit workflow). Scoping to "CODE CONVENTIONS and PATTERNS" with explicit carveout for "task execution instructions" prevents this conflict.

---

## Edge Cases

| Scenario | Handling |
|----------|----------|
| No `.claude/experts/` directory exists | Tier 2 ephemeral generation still works. No common experts = all ephemeral. |
| Task Context paths reference files that don't exist yet | Skip expert generation for that group; use unadorned general-purpose dispatch |
| Monorepo with same domain name in multiple packages | Include package name in domain: `api-auth-expert.md` vs `web-auth-expert.md` |
| Cross-cutting task (middleware, config) touching many domains | Domain inference returns ambiguous result → skip expert injection, use generic dispatch |
| 10+ domains detected during init | Cap at 5-6 most prominent domains. User can run init with `--force` to regenerate |
| Expert file manually edited by user | Respect edits. Staleness check in Audit Mode warns but does not overwrite without confirmation |
| Polyglot codebase | Generate separate experts per language-domain pair (e.g., `python-api-expert.md`, `typescript-frontend-expert.md`) |
| Domain inference yields empty string | Validation catches this → skip expert injection, use generic dispatch |
| Multiple experts match same domain | Prefer expert where domain appears first in `domains` list (primary domain) |
| Ephemeral generation produces output outside 250-350 word budget | Orchestrator prompt constrains this. If wildly off, truncate to 350 words. |
| Sparse domain (< 3 files, no tests) | Omit empty convention bullets. Shorter expert is fine. If < 2 convention bullets extractable, skip expert entirely. |

---

## Open Questions

1. **Should `.claude/experts/` be gitignored or committed?** Committing makes them available to all team members. Gitignoring treats them as local cache. Recommendation: commit them (they contain project conventions, not secrets), but note this in init output.

2. **Should there be a standalone command to regenerate experts?** Something like `/ce:init --experts-only` to regenerate without re-running full init. Low priority but useful for projects that evolve frequently.

3. **Forward-compatibility of `.claude/experts/`:** Claude Code could introduce new reserved directories under `.claude/` in future versions. Consider namespacing as `.claude/ce-experts/` if this becomes a concern. Current assessment: low risk.
