---
description: Verify ACFS toolchain is properly installed and configured
argument-hint: "[--fix]"
allowed-tools: Bash, Read
---

Check that all ACFS tools are installed and accessible. Run diagnostics on each tool and report status.

## Required Tools

Check each tool in order. For each tool, verify:
1. Command exists in PATH
2. Basic functionality works (e.g., `--version` or `--help`)
3. Report status as PASS/FAIL/WARN

### Core Tools (Required)

| Tool | Check Command | Purpose |
|------|---------------|---------|
| `br` | `br --version` | Beads CLI for issue tracking |
| `bv` | `bv --help` | Beads Viewer for task management |
| `cass` | `cass --version` | Cross-agent session search |
| `cm` | `cm --version` | Cass Memory for procedural knowledge |
| `ubs` | `ubs --version` | Ultimate Bug Scanner |

### Coordination Tools (Required for multi-agent)

| Tool | Check Command | Purpose |
|------|---------------|---------|
| `mcp_agent_mail` | `mcp_agent_mail --version` | Inter-agent messaging and file reservations |
| `ntm` | `ntm --version` | Named Tmux Manager for session orchestration |
| `dcg` | `dcg status` | Destructive Command Guard |
| `slb` | `slb --version` | Simultaneous Launch Button (two-person rule) |
| `ru` | `ru --version` | Repo Updater for multi-repo sync |

### Utility Tools (Optional)

| Tool | Check Command | Purpose |
|------|---------------|---------|
| `giil` | `giil --version` | Cloud image downloader |
| `csctf` | `csctf --version` | Chat share to markdown converter |

## Execution

1. Run each check command, capturing exit code and output
2. For failed tools, check if they might be installed elsewhere
3. Summarize results in a table

## Output Format

```
ACFS Doctor - Toolchain Verification
====================================

Core Tools:
  [PASS] br v1.2.3 - Beads CLI
  [PASS] bv v1.0.0 - Beads Viewer
  [FAIL] cass - Not found in PATH
  ...

Coordination Tools:
  [PASS] mcp_agent_mail v2.0.0 - Agent Mail
  [WARN] ntm v1.1.0 - Named Tmux Manager (tmux not running)
  ...

Summary: 8/10 tools available
  - 2 missing: cass, slb
  - 1 warning: ntm (tmux not active)

Recommendations:
  - Install missing tools: curl -fsSL https://... | bash
  - Start tmux session for ntm functionality
```

## If `--fix` argument provided

Suggest installation commands for missing tools. Do NOT run installation automatically - just provide the commands.

## Environment Checks

Also verify:
1. `.beads/` directory exists (ACFS project initialized)
2. Agent identity is registered (if mcp_agent_mail available)
3. DCG hooks are active (if dcg available)
