---
name: writing-plans
description: Create comprehensive, context-aware implementation plans using TDD and Spec-Driven patterns
---

# Writing Plans

Write detailed, step-by-step implementation plans designed for an agentic coding workflow. Assume the executor has zero context. The plan must act as a single source of truth, containing the spec, context, and execution steps.

**Save plans to:** `./plans/YYYY-MM-DD-<feature-name>.md`

**For large plans (1000+ lines):** Split into multiple files within a folder at `./plans/YYYY-MM-DD-<feature-name>/` (see "Multi-File Plan Structure" section below)

## Plan Document Structure

````

# [Feature Name] Implementation Plan

> **Status:** DRAFT | APPROVED | IN_PROGRESS | COMPLETED

## 1. Specification

**User Story:** [As a... I want to... So that...]
**Success Criteria:**

- [ ] Criterion 1
- [ ] Criterion 2

## 2. Architecture & Strategy

**Approach:** [High-level technical approach]
**Key Components:**

- `ComponentA`: Responsibilities...
- `ComponentB`: Responsibilities...

## 3. Context Loading

_Instructions for the agent: Run these commands to load necessary context before starting._

```bash
glob src/relevant/path/*.ts
read src/specific/interface.ts
load Skill(command=<a relevant skill related to the task>)
````

---

## 4. Implementation Tasks

### Task [N]: [Component/Feature Name]

**Goal:** [Brief description of what this specific task achieves]

**Relevant Files:**

- `src/path/to/file.ts`
- `tests/path/to/file.test.ts`

**Step 1: TDD - Red (Failing Test)**

- [ ] Create/Modify test file: `tests/path/to/file.test.ts`
- [ ] Add test case: `it('should [expected behavior]...')`
- [ ] **VERIFY:** Run `npm test -- tests/path/to/file.test.ts`
  - _Expected Output:_ `FAIL` (ReferenceError or expectation mismatch)

**Step 2: TDD - Green (Minimal Implementation)**

- [ ] Create/Modify source file: `src/path/to/file.ts`
- [ ] Implement minimal code to satisfy the test.
- [ ] **VERIFY:** @example Run `yarn test -- tests/path/to/file.test.ts`
  - _Expected Output:_ `PASS`

**Step 3: Refactor & Integration**

- [ ] Optimize code if necessary (clean up types, remove hardcoding).
- [ ] Run linter: @example `yarn lint`
- [ ] **COMMIT:** use the `/ce:commit` command

---

### Task [N+1]: [Next Component]

...

````

## Best Practices for Plan Generation

1.  **Explicit file paths:** Never say "create a utility." Say "create `src/utils/string-helpers.ts`."
2.  **One-shot context:** The "Context Loading" section is vital. It tells the implementing agent *exactly* what to read so it doesn't waste tokens searching the file tree.
3.  **Verification is mandatory:** Every code change must have a corresponding CLI command to verify it (test, lint, etc).
4.  **Atomic Commits:** Each task ends with a commit. This creates save points.

## Multi-File Plan Structure

When a plan exceeds ~1000 lines, break it into multiple files to keep each document focused and manageable. Create a folder instead of a single file.

**Folder structure:**
```
./plans/YYYY-MM-DD-<feature-name>/
├── README.md              # Main overview and tracking (always start here)
├── phase-1-<name>.md      # First major phase
├── phase-2-<name>.md      # Second major phase
└── phase-N-<name>.md      # Additional phases as needed
```

**README.md (Main Overview):**
```markdown
# [Feature Name] Implementation Plan

> **Status:** DRAFT | APPROVED | IN_PROGRESS | COMPLETED

## 1. Specification

**User Story:** [As a... I want to... So that...]
**Success Criteria:**

- [ ] Criterion 1
- [ ] Criterion 2

## 2. Architecture & Strategy

**Approach:** [High-level technical approach]
**Key Components:**

- `ComponentA`: Responsibilities...
- `ComponentB`: Responsibilities...

## 3. Context Loading

_Instructions for the agent: Run these commands to load necessary context before starting._

```bash
glob src/relevant/path/*.ts
read src/specific/interface.ts
```

## 4. Phase Overview & Progress

| Phase | Document | Status | Description |
|-------|----------|--------|-------------|
| 1 | [phase-1-foundation.md](./phase-1-foundation.md) | NOT_STARTED | Core infrastructure setup |
| 2 | [phase-2-features.md](./phase-2-features.md) | NOT_STARTED | Feature implementation |
| 3 | [phase-3-integration.md](./phase-3-integration.md) | NOT_STARTED | Integration and polish |

## 5. Execution Order

1. Load context (Section 3)
2. Complete Phase 1 before starting Phase 2
3. Phases may have internal parallelization noted in their docs
```

**Phase document structure:**
Each phase document follows the same task format as single-file plans but focuses on one logical grouping of work.

```markdown
# Phase N: [Phase Name]

> **Status:** NOT_STARTED | IN_PROGRESS | COMPLETED
> **Prerequisites:** [List any phases that must complete first]

## Context Loading (Phase-Specific)

_Additional context needed for this phase:_

```bash
read src/specific/to/this/phase.ts
```

## Tasks

### Task N.1: [Component Name]
[Standard TDD task format...]

### Task N.2: [Next Component]
[Standard TDD task format...]
```

**When to split:**
- Plan is approaching or exceeding 1000 lines
- Natural phase boundaries exist (setup, core features, integration, etc.)
- Multiple developers might work on different phases
- You want to track progress at a phase level

## Post-Generation Prompt

**For single-file plans:**

> Plan saved to `./plans/YYYY-MM-DD-<feature-name>.md`.
>
> To execute this plan:
> 1. **Load Context:** Run the commands in Section 3.
> 2. **Execute Task 1:** Use the `Skill(ce:executing-plans)` skill.
>
> Shall I initialize the plan file now?

**For multi-file plans:**

> Plan saved to `./plans/YYYY-MM-DD-<feature-name>/`.
>
> Files created:
> - `README.md` - Main overview and progress tracking
> - `phase-1-<name>.md` - [Description]
> - `phase-2-<name>.md` - [Description]
> - ...
>
> To execute this plan:
> 1. **Load Context:** Run the commands in README.md Section 3.
> 2. **Execute Phase 1:** Open `phase-1-<name>.md` and use `Skill(ce:executing-plans)`.
> 3. **Update Progress:** Mark phases complete in README.md as you finish them.
>
> Shall I initialize the plan folder now?
```

### Explanation of Design Decisions
1.  **Folder Convention (`./plans/`)**: Moving plans to a dedicated directory prevents clutter in the root and makes it easier to `.gitignore` or organize planning documents.
2.  **Context Loading Section**: This is the single biggest quality-of-life improvement for Claude Code. By explicitly listing `glob` and `read` commands, you allow the executing agent to hydrate its context immediately without hallucinating file structures.
3.  **Status & Metadata**: Added a header block for status. This is useful when you pause and resume sessions; the agent can read the status line to know where it left off.
4.  **Split Verification**: The original "Step 1" combined writing and running. Splitting them forces the agent to *stop* and actually run the command, which catches environment issues (like missing dependencies) before code is written.
5.  **Multi-File Plans**: Large plans (1000+ lines) get unwieldy in a single file. Breaking them into phases with a central README provides: clear progress tracking at the phase level, ability to work on phases independently, reduced cognitive load when reading any single document, and natural parallelization boundaries for team work.
