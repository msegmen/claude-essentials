---
name: executing-plans
description: Execute implementation plans. One task = one agent. Parallelize independent tasks.
---

# Executing Plans

Execute plans by dispatching one agent per task. A task is a complete unit of work - all its steps are handled by a single agent.

## Core Rules

1. **One task = one agent** - Never split a task across multiple agents
2. **Parallelize tasks** - Independent tasks (different subsystems) can run in parallel
3. **Never parallelize steps** - Steps within a task are sequential, same agent

## Execution Flow

Copy this checklist and track your progress:

```
Plan Execution Progress:
- [ ] Step 1: Load the plan file
- [ ] Step 2: Create TodoWrite with all tasks
- [ ] Step 3: Dispatch agents for independent tasks in parallel
- [ ] Step 4: Update plan file (mark IN_PROGRESS)
- [ ] Step 5: Wait for completion, dispatch dependent tasks
- [ ] Step 6: Run final verification (tests, build, lint)
- [ ] Step 7: Dispatch code-reviewer agent
- [ ] Step 8: Update plan status to COMPLETED
```

1. Load the plan file
2. Create TodoWrite with all tasks
3. Evaluate the skills relevant to each task
4. Dispatch agents for independent tasks in parallel, include the skills the agent should use
5. **Update plan file** - Mark task checkboxes complete, update status to IN_PROGRESS
6. Wait for completion, then dispatch dependent tasks
7. Run final verification (tests, build, lint)
8. Dispatch `ce:code-reviewer` for review
9. **Update plan status** to COMPLETED when done

## Task Dispatch

```
# Independent tasks - dispatch in parallel
Task tool (general-purpose):
  description: "Task 1: Add auth module"
  prompt: |
    Execute Task 1 from [plan-file].
    Use the following skills: <list skills that fit the task>
    Complete ALL steps in this task.
    Verify and commit when done.
    Report: files changed, test results

Task tool (general-purpose):
  description: "Task 2: Add billing module"
  prompt: |
    Execute Task 2 from [plan-file].
    Use the following skills: <list skills that fit the task>
    Complete ALL steps in this task.
    Verify and commit when done.
    Report: files changed, test results
```

## When to Parallelize

**Parallel:** Tasks touch different subsystems with no file overlap

```
Task 1: src/auth/*      ─┬─ parallel
Task 2: src/billing/*   ─┘
```

**Sequential:** Tasks have dependencies or shared files

```
Task 1: Create types    → Task 2: Use types (depends on 1)
```

**Combine:** Multiple small changes in same area should be one task in one agent, not parallel tasks

## Agent Selection

- **general-purpose**: Default for most tasks
- **ce:haiku**: Only for purely mechanical tasks (copy file, add single export, log parse, etc)

## Progress Tracking

Update the plan file as you execute:

1. Set plan status to `IN_PROGRESS` when starting
2. Check off `[x]` each step as agents complete them
3. After each task completes, verify its checkbox steps are marked done
4. Set plan status to `COMPLETED` when all tasks pass verification

This keeps the plan file as the source of truth for progress.

## Auto-Recovery

If a task fails:

1. Dispatch a fix agent with the error output
2. If same error twice, stop and ask user

## Final Verification

After all tasks:

1. Run full test suite and linters
2. Run build
3. Dispatch `ce:code-reviewer` agent to review changes
4. Plan and fix issues found
5. Mark plan COMPLETED
