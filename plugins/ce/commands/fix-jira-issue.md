---
description: Fix a Jira issue by key
argument-hint: "<issue-key>"
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
---

Fetch a Jira issue and implement a fix for it.

Arguments:

- `$ARGUMENTS`: Required. The Jira issue key (e.g., "LUNA-123")

Process:

1. Fetch the issue details using Atlassian MCP:
   - Use `getJiraIssue` tool with the issue key
   - If cloudId is needed and not configured, ask user for their Atlassian site URL

2. Analyze the issue:
   - Understand what's being requested or what bug is reported
   - Check issue type (Bug, Story, Task, etc.) and priority
   - Review any comments for additional context
   - Identify acceptance criteria if specified in description

3. Explore the codebase:
   - Find relevant files mentioned in the issue
   - Understand the current implementation
   - Identify where changes need to be made

4. Plan the fix:
   - Break down the work into steps
   - Consider edge cases mentioned in the issue
   - Think about testing requirements

5. Create a git worktree for isolated development:
   - Create a new branch named after the issue key (e.g., `LUNA-123`)
   - Create a worktree in a sibling directory: `git worktree add ../worktrees/<issue-key> -b <issue-key>`
   - Change to the worktree directory to make changes there
   - This keeps the main workspace clean while working on the fix

6. Implement the fix:
   - Make the necessary code changes
   - Follow existing code patterns and style
   - Keep changes focused on the issue scope

7. Verify the fix:
   - Run relevant tests
   - Check that acceptance criteria are met
   - Ensure no regressions

8. Summarize what was done:
   - List files changed
   - Explain the approach taken
   - Provide the worktree path for review
   - Note any follow-up items or considerations

Do not automatically commit or create a PR. Let the user review the changes in the worktree first and decide when to commit.

If the issue key is not provided or the issue cannot be found, ask for clarification.
