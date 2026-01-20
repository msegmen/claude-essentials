#!/usr/bin/env bash
# ACFS SessionStart hook
# - Detects ACFS project (.beads/ directory)
# - Registers agent identity (if mcp_agent_mail available)
# - Checks for pending messages and file reservations
# - Loads pending handoffs
# - Injects skills list for subagent visibility

set -euo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SKILLS_DIR="${PLUGIN_ROOT}/skills"

# Build context messages
CONTEXT_PARTS=()

# ============================================================
# 1. ACFS Project Detection
# ============================================================
detect_acfs_project() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.beads" ]]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

ACFS_ROOT=""
if ACFS_ROOT=$(detect_acfs_project); then
    CONTEXT_PARTS+=("[ACFS] Project detected at: $ACFS_ROOT")
else
    # Not an ACFS project - still inject skills but skip ACFS-specific checks
    CONTEXT_PARTS+=("[ACFS] No .beads/ directory found - ACFS workflows not available")
fi

# ============================================================
# 2. Agent Identity Registration (if mcp_agent_mail available)
# ============================================================
if command -v mcp_agent_mail &>/dev/null && [[ -n "$ACFS_ROOT" ]]; then
    # Try to register identity
    if identity_output=$(mcp_agent_mail identity --register --robot --json 2>/dev/null); then
        agent_id=$(echo "$identity_output" | grep -o '"agent_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 || true)
        if [[ -n "$agent_id" ]]; then
            CONTEXT_PARTS+=("[ACFS] Agent identity registered: $agent_id")
        fi
    fi
fi

# ============================================================
# 3. Pending Messages Check
# ============================================================
if command -v mcp_agent_mail &>/dev/null && [[ -n "$ACFS_ROOT" ]]; then
    if messages_output=$(mcp_agent_mail inbox --robot --json 2>/dev/null); then
        msg_count=$(echo "$messages_output" | grep -o '"unread"[[:space:]]*:[[:space:]]*[0-9]*' | head -1 | grep -o '[0-9]*' || echo "0")
        if [[ "$msg_count" -gt 0 ]]; then
            CONTEXT_PARTS+=("[ACFS] ATTENTION: $msg_count unread message(s) - run /acfs:message to view")
        fi
    fi
fi

# ============================================================
# 4. File Reservations Check
# ============================================================
if command -v mcp_agent_mail &>/dev/null && [[ -n "$ACFS_ROOT" ]]; then
    if reservations_output=$(mcp_agent_mail leases --robot --json 2>/dev/null); then
        # Check for any reservations that might conflict
        reservation_count=$(echo "$reservations_output" | grep -c '"file"' || echo "0")
        if [[ "$reservation_count" -gt 0 ]]; then
            CONTEXT_PARTS+=("[ACFS] WARNING: $reservation_count file reservation(s) active - check before editing reserved files")
        fi
    fi
fi

# ============================================================
# 5. Pending Handoffs Check
# ============================================================
if [[ -n "$ACFS_ROOT" && -d "$ACFS_ROOT/.beads/handoffs" ]]; then
    # Find most recent handoff
    latest_handoff=$(ls -t "$ACFS_ROOT/.beads/handoffs/"*.md 2>/dev/null | head -1 || true)
    if [[ -n "$latest_handoff" && -f "$latest_handoff" ]]; then
        handoff_name=$(basename "$latest_handoff")
        CONTEXT_PARTS+=("[ACFS] Pending handoff available: $handoff_name - run /acfs:recall to load context")
    fi
fi

# ============================================================
# 6. Build Skills List (same pattern as ce: plugin)
# ============================================================
parse_skill() {
    local skill_file="$1"
    local in_frontmatter=false
    local name=""
    local desc=""

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if $in_frontmatter; then
                break
            fi
            in_frontmatter=true
            continue
        fi
        if $in_frontmatter; then
            if [[ "$line" =~ ^name:\ *(.+)$ ]]; then
                name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^description:\ *(.+)$ ]]; then
                desc="${BASH_REMATCH[1]}"
            fi
        fi
    done < "$skill_file"

    if [[ -n "$name" && -n "$desc" ]]; then
        if [[ ${#desc} -gt 200 ]]; then
            desc="${desc:0:200}"
            desc="${desc% *}..."
        fi
        echo "acfs:${name}|${desc}"
    fi
}

SKILL_NAMES=()
SKILLS_LIST=""

if [[ -d "$SKILLS_DIR" ]]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
        skill_file="${skill_dir}SKILL.md"
        if [[ -f "$skill_file" ]]; then
            skill_data=$(parse_skill "$skill_file")
            if [[ -n "$skill_data" ]]; then
                skill_name="${skill_data%%|*}"
                skill_desc="${skill_data#*|}"
                SKILL_NAMES+=("$skill_name")
                SKILLS_LIST="${SKILLS_LIST}- ${skill_name}: ${skill_desc}
"
            fi
        fi
    done
fi

# ============================================================
# 7. Output Context if Needed
# ============================================================
if [[ ${#CONTEXT_PARTS[@]} -gt 0 || -n "$SKILLS_LIST" ]]; then
    OUTPUT_TEXT=""

    # Add ACFS context
    if [[ ${#CONTEXT_PARTS[@]} -gt 0 ]]; then
        OUTPUT_TEXT+="## ACFS Session Status

"
        for part in "${CONTEXT_PARTS[@]}"; do
            OUTPUT_TEXT+="$part
"
        done
        OUTPUT_TEXT+="
"
    fi

    # Add skills list
    if [[ -n "$SKILLS_LIST" ]]; then
        OUTPUT_TEXT+="## Available ACFS Skills

Use Skill(acfs:<skill-name>) to activate:

${SKILLS_LIST}"
    fi

    # Output JSON for Claude Code
    json_content=$(printf '%s' "$OUTPUT_TEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])')

    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${json_content}"
  }
}
EOF
fi

exit 0
