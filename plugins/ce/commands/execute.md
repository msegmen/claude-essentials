---
description: Execute an implementation plan from the plans folder
argument-hint: "[plan-path]"
allowed-tools: Read, Glob, Bash, Task, Skill, AskUserQuestion, TodoWrite
---

Execute an implementation plan using the executing-plans skill.

Load the skill first: `Skill(ce:executing-plans)`

## Workflow

### If no arguments provided (`$ARGUMENTS` is empty):

1. **Find available plans:**
   Search recursively for plan files regardless of folder structure:
   ```bash
   glob ./**/plans/**/*.md
   glob ./**/plans/**/README.md
   glob ./plans/**/*.md
   glob ./plans/**/README.md
   ```

   Also check common alternative locations:
   ```bash
   glob ./**/*-PLAN.md
   glob ./**/*-plan.md
   ```

   **Identify plan files by:**
   - Files in any `plans/` directory at any depth
   - Files with `-PLAN.md` or `-plan.md` suffix
   - Files containing `> **Status:**` header pattern
   - For multi-file plans: `README.md` files that contain a phase table

2. **Filter to incomplete plans:**
   - Read each plan file
   - Check the `> **Status:**` header
   - Only show plans with status `DRAFT`, `APPROVED`, or `IN_PROGRESS`
   - Skip plans marked `COMPLETED`

3. **Present options:**
   List incomplete plans with their status and a brief description (from the User Story or first line of spec).

   Use `AskUserQuestion` to let the user select which plan to execute:
   ```
   Which plan would you like to execute?
   - [plan-1-name] (APPROVED) - Brief description
   - [plan-2-name] (IN_PROGRESS) - Brief description
   ```

4. **Load the selected plan** and proceed to execution prep below.

### If plan path provided (`$ARGUMENTS` has a value):

1. **Read the plan:**
   - If path ends in `.md`: single-file plan
   - If path is a directory or ends in `/`: multi-file plan, read `README.md`

2. **Verify plan exists and is executable:**
   - Check status is not `COMPLETED`
   - If `COMPLETED`, ask if user wants to re-execute

### Execution Prep (both paths):

1. **Review the plan:**
   - Display the specification and success criteria
   - Show the high-level task/phase breakdown
   - For multi-file plans, show the phase table with current progress

2. **Ask clarifying questions if needed:**
   - Ambiguous requirements
   - Missing context that can't be inferred
   - Unclear dependencies or ordering

3. **Confirm execution:**
   Ask: "Ready to execute this plan? This will run tasks autonomously and commit changes as each task completes."

4. **Execute:**
   Follow the `Skill(ce:executing-plans)` workflow - it handles:
   - Dependency analysis and wave computation
   - Parallel task execution
   - Auto-recovery from errors
   - Progress tracking and status updates
   - Final verification and code review
   - Archiving completed plan to `done/` folder
   - Completion summary
