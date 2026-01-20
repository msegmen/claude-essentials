---
name: multi-agent-workflows
description: Orchestrates parallel work across multiple agents using NTM sessions. Use when coordinating complex tasks across multiple Claude instances.
---

# Multi-Agent Workflows

When work can be parallelized across multiple agents, proper orchestration ensures efficiency without conflicts.

## When to Use Multiple Agents

- Large refactoring across many files
- Independent feature development
- Parallel testing and implementation
- Code review while continuing work

## NTM Session Management

### Spawn New Session

```bash
ntm spawn <name> --command "claude" --robot --json
```

Creates a named tmux window with a new Claude session.

### List Sessions

```bash
ntm list --robot --json
```

Shows all active sessions:
```
agent-main    | Active | 2h uptime | ACFS-42
agent-review  | Active | 30m uptime | Code review
agent-test    | Idle   | 1h uptime | -
```

### Switch Session

```bash
ntm attach <name>
```

### Close Session

```bash
ntm close <name> --robot --json
```

## Work Distribution

### Pattern 1: Parallel Features

```
Main Agent: Coordinate
├── Agent A: Feature X (files: src/feature-x/*)
├── Agent B: Feature Y (files: src/feature-y/*)
└── Agent C: Feature Z (files: src/feature-z/*)
```

Each agent:
1. Claims files via reservations
2. Works independently
3. Commits to feature branch
4. Signals completion

Main agent:
1. Monitors progress via messages
2. Coordinates integration
3. Handles merge conflicts

### Pattern 2: Review While Working

```
Main Agent: Implementation
└── Review Agent: Code review
```

Steps:
1. Main creates PR/commits
2. Spawn review agent: `ntm spawn reviewer`
3. Review agent examines changes
4. Feedback via messages
5. Main incorporates feedback

### Pattern 3: Test and Fix

```
Test Agent: Run tests, report failures
Fix Agent: Fix failing tests
```

Parallel loop:
1. Test agent runs suite
2. Reports failures via message
3. Fix agent claims failed test files
4. Fixes and commits
5. Test agent re-runs

## Coordination Protocol

### Starting Parallel Work

1. **Plan division**: Identify independent work streams
2. **Assign files**: Each agent reserves their files
3. **Create issues**: Each work stream gets an issue
4. **Spawn agents**: `ntm spawn` for each stream
5. **Distribute**: Message each agent their assignment

### During Parallel Work

- **Progress updates**: Regular status messages
- **Blocking notifications**: Immediate notification if blocked
- **File requests**: Message if need files another has
- **Decision escalation**: Route to main agent

### Completing Parallel Work

1. **Individual completion**: Each agent runs /acfs:complete
2. **Integration**: Main agent merges branches
3. **Conflict resolution**: Main handles any conflicts
4. **Final validation**: Run full test suite
5. **Cleanup**: Close spawned sessions

## Safety Measures

### Prevent Conflicts

- Always reserve files before editing
- Check leases before any edit
- Communicate file needs via messages

### Prevent Divergence

- Regular commits (at least hourly)
- Rebase frequently from main
- Immediate push after completion

### Prevent Loss

- All agents follow completion protocol
- Main agent verifies all work pushed
- Handoffs for any incomplete work

## Orchestrator Responsibilities

The orchestrator agent (or main agent) must:

1. **Plan**: Divide work, identify dependencies
2. **Assign**: Distribute to appropriate agents
3. **Monitor**: Track progress via messages
4. **Unblock**: Handle blockers quickly
5. **Integrate**: Merge completed work
6. **Verify**: Ensure all work captured

## Message Patterns

### Assignment
```
"ASSIGNMENT: Work on ACFS-55. Files: src/api/*. Branch: feature/api-v2.
Reserved files for you. Report progress every 30 min."
```

### Progress Report
```
"PROGRESS: ACFS-55 at 60%. Completed endpoint refactor.
Starting validation logic next. ETA: 45 min."
```

### Completion
```
"COMPLETE: ACFS-55 done. Pushed to feature/api-v2.
All tests passing. Ready for merge."
```

### Block Notification
```
"BLOCKED: Need src/auth/index.ts for ACFS-55.
Currently reserved by agent-42. Can you coordinate?"
```
