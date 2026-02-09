# Expert Generation (Step 2.5)

Generate persistent common domain experts by scanning the codebase for major technology domains, extracting project-specific conventions from representative files, and writing expert prompt files to `.claude/experts/`. These experts are injected into subagent dispatches during plan execution to replace generic execution with domain-aware execution.

## Domain Detection

Scan the project structure (top-level `src/` or equivalent, 2 levels deep) to identify directories with 3+ files that represent distinct domains.

**Detection heuristics (priority order):**

| Signal | Domain | Example |
|--------|--------|---------|
| Directory name under `src/` | Named domain | `src/auth/` -> `auth` |
| Framework-specific directories | Framework domain | `app/api/` -> `api`, `components/` -> `frontend` |
| Test directories with domain mirrors | Confirms domain | `tests/auth/` confirms `auth` |
| Package directories in monorepos | Scoped domain | `packages/api/` -> `api` |

**Rules:**

- Shared/infrastructure directories are **never** a domain: `utils/`, `lib/`, `common/`, `shared/`, `helpers/`, `types/`, `config/`, `scripts/`, `fixtures/`, `vendor/`, `internal/`, `public/`, `static/`, `__tests__/`, `__mocks__/`, `__pycache__/`, `.next/`, `dist/`, `build/`, `node_modules/`.
- In monorepos, include the package name in domain: `api-auth`, `web-auth`.
- If a domain directory has 15+ files with clear subdirectories, consider subdomain experts.
- Maximum 5-6 common experts per project. More yields diminishing returns.

## Convention Extraction

For each identified domain, read 3-5 representative files and extract project-specific patterns.

**Extraction checklist:**

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

**What NOT to extract:** Generic domain knowledge the model already has. Only include project-specific patterns observed in actual files. The generation prompt must instruct: "Only include patterns you observed in the files you read. Do not add generic domain advice."

**Sparse results:** If a domain has fewer than 3 files or no test files, omit the corresponding convention bullets entirely rather than writing "No pattern observed." A shorter, factual expert is better than one padded with empty sections. If fewer than 2 convention bullets are extractable, skip generating an expert for that domain entirely.

## Expert Prompt Template

Write expert files to `.claude/experts/<domain>-expert.md`. Create the directory with `mkdir -p` if it does not exist.

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

**The `domains` frontmatter field** enables robust matching at dispatch time. Include the primary domain name plus common aliases and path variations.

Examples:

```yaml
# Auth expert generated from src/auth/
domains: [auth, authentication, user-auth]

# Frontend expert generated from src/components/
domains: [frontend, components, ui, web]

# Monorepo API expert
domains: [api-auth, api-authentication]
```

**Constraints:**

- 400-600 words per expert. Tight enough to avoid attention dilution, long enough for code examples.
- Code snippets: 5-10 lines each, showing structure not full implementations.
- Metadata tracks provenance for staleness detection.
- Boundaries use positive redirections, not bare negations.
- No Execution Contract section -- execution mechanics belong in the dispatch template, not domain experts.

**When approaching the 600-word ceiling, cut content in this priority order (bottom first):**

1. Second code example (keep one)
2. Boundary details (keep to one sentence)
3. Less-critical convention bullets (keep language, naming, testing)

## Generation Plan Display

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
  └── experts/
      ├── api-expert.md           # Express API conventions
      ├── frontend-expert.md      # React component patterns
      ├── database-expert.md      # Prisma/SQL patterns
      └── testing-expert.md       # Jest/Vitest patterns
```

## Self-Improvement After Execution

Experts improve through an Act-Learn-Reuse cycle during plan execution (see `ce:executing-plans` step 6). After each plan completes, the orchestrator compares `git diff` output against the expert's conventions and makes targeted updates when drift is detected.

**What triggers an update:**
- New libraries imported that the expert doesn't mention
- Changed naming or error handling patterns
- New test patterns or structural reorganization
- 3+ files modified in the expert's domain

**What doesn't trigger an update:**
- Fewer than 3 files changed in the domain
- Expert was updated less than 24 hours ago
- Changes follow existing conventions (no drift)

**Update rules:**
- Patch, don't regenerate. Edit specific convention bullets and swap stale code snippets.
- Stay within 400-600 words. If an update would exceed the ceiling, apply the cutting priority: drop second code example first, then boundary details, then less-critical convention bullets.
- Bump `generated_at` and `source_files` in frontmatter.
- Commit expert updates separately from feature work.

**Ephemeral-to-persistent promotion:** If `ce:executing-plans` generated an ephemeral expert for a domain that now has 5+ files with clear conventions, promote it to a persistent expert using the full template above.

## `--force` Behavior

When `/ce:init --force` is used, regenerate all experts without confirmation.

## Audit Mode Checks

In Audit Mode, check for missing and stale experts.

**Missing experts:** Detect major domains in the codebase that lack corresponding expert files in `.claude/experts/`.

**Stale experts:** Compare the `generated_at` timestamp in expert frontmatter against the file modification times of the listed `source_files`. If source files changed since expert generation, flag the expert for update.

**Report format:**

```
Experts:
  + api-expert.md: Up to date
  - frontend-expert.md: Stale (src/components/ modified since generation)
  - Missing: database-expert.md (detected Prisma in src/db/)

Regenerate stale/missing experts? [Y/n]
```
