---
description: Create or improve documentation (routes to appropriate doc agent)
argument-hint: "<file-path-or-doc-type>"
allowed-tools: Bash, Task, Read, Glob, AskUserQuestion
---

Create or improve documentation by routing to the appropriate documentation agent.

Arguments:

- `$ARGUMENTS`: File path, doc type, or description of documentation needed

## Routing Logic

Analyze the arguments and context to determine the correct agent:

**Route to `@ce:code-commenter` agent when:**

- Single source code file path provided (`.ts`, `.js`, `.py`, `.go`, `.rs`, etc.)
- Request mentions "comments", "inline docs", or "code comments"
- Task is auditing/cleaning up comments in a single file
- Task is asking to clean up comments in a group of files: find changed files via `git status -s` or by scoping to the folder the user specified and pass the requested files to document/refactor the code-commenter agent

**Route to `@ce:complex-doc-writer` agent when:**

- Markdown file path provided (`.md`)
- Request mentions README, API docs, architecture, or `/docs/`
- Task spans multiple files or requires system-level understanding
- Request is for new documentation (guides, references, etc.)

## Process

1. **Parse arguments**: Determine what the user wants documented
2. **Detect scope**:
   - If file path provided, check extension and file type
   - If no path, analyze the request description
3. **Route to agent**:
   - Invoke `@ce:simple-doc-writer` agent for single-file code comment work
   - Invoke `@ce:complex-doc-writer` agent for markdown/multi-file documentation
4. **If ambiguous**: Ask user to clarify scope before proceeding

## Examples

| Input                                                  | Routes To          |
| ------------------------------------------------------ | ------------------ |
| `/document src/utils/auth.ts`                          | simple-doc-writer  |
| `/document clean up code comments in unstaged changes` | simple-doc-writer  |
| `/document README`                                     | complex-doc-writer |
| `/document API docs for /users endpoint`               | complex-doc-writer |
| `/document clean up comments in parser.py`             | simple-doc-writer  |
| `/document architecture overview`                      | complex-doc-writer |
