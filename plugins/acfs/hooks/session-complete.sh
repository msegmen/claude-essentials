#!/usr/bin/env bash
# ACFS Session Complete hook (Stop event)
# - Warns on uncommitted/unpushed changes
# - Warns on unreleased file reservations
# - Suggests /acfs:complete if gates not satisfied

set -euo pipefail

WARNINGS=()

# ============================================================
# 1. Check for ACFS Project
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
if ! ACFS_ROOT=$(detect_acfs_project); then
    # Not an ACFS project - exit silently
    exit 0
fi

# ============================================================
# 2. Check for Uncommitted Changes
# ============================================================
if command -v git &>/dev/null; then
    if git rev-parse --git-dir &>/dev/null; then
        # Check for uncommitted changes
        if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
            WARNINGS+=("UNCOMMITTED CHANGES: You have uncommitted changes. Run 'git status' to review.")
        fi

        # Check for untracked files in important directories
        untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l || echo "0")
        if [[ "$untracked_count" -gt 0 ]]; then
            WARNINGS+=("UNTRACKED FILES: $untracked_count untracked file(s). Consider adding or ignoring them.")
        fi
    fi
fi

# ============================================================
# 3. Check for Unpushed Commits (CRITICAL)
# ============================================================
if command -v git &>/dev/null; then
    if git rev-parse --git-dir &>/dev/null; then
        # Get upstream branch
        upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)
        if [[ -n "$upstream" ]]; then
            unpushed=$(git rev-list --count "$upstream"..HEAD 2>/dev/null || echo "0")
            if [[ "$unpushed" -gt 0 ]]; then
                WARNINGS+=("UNPUSHED COMMITS: $unpushed commit(s) not pushed to remote. Work is NOT complete until 'git push' succeeds!")
            fi
        else
            # No upstream set
            local_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            if [[ "$local_commits" -gt 0 ]]; then
                WARNINGS+=("NO UPSTREAM: Branch has no upstream set. Commits may not be pushed!")
            fi
        fi
    fi
fi

# ============================================================
# 4. Check for Active File Reservations
# ============================================================
if command -v mcp_agent_mail &>/dev/null; then
    if reservations_output=$(mcp_agent_mail leases --mine --robot --json 2>/dev/null); then
        my_reservations=$(echo "$reservations_output" | grep -c '"file"' || echo "0")
        if [[ "$my_reservations" -gt 0 ]]; then
            WARNINGS+=("FILE RESERVATIONS: You have $my_reservations active file reservation(s). Release with '/acfs:complete' or 'mcp_agent_mail release --all'")
        fi
    fi
fi

# ============================================================
# 5. Check for In-Progress Issues
# ============================================================
if command -v br &>/dev/null; then
    if issues_output=$(br list --status in-progress --robot --json 2>/dev/null); then
        in_progress_count=$(echo "$issues_output" | grep -c '"id"' || echo "0")
        if [[ "$in_progress_count" -gt 0 ]]; then
            WARNINGS+=("IN-PROGRESS ISSUES: $in_progress_count issue(s) still in-progress. Update status with '/acfs:update' or close with '/acfs:complete'")
        fi
    fi
fi

# ============================================================
# 6. Output Warnings
# ============================================================
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    OUTPUT_TEXT="## ACFS Session Completion Warnings

"
    for warning in "${WARNINGS[@]}"; do
        OUTPUT_TEXT+="- $warning
"
    done
    OUTPUT_TEXT+="
**Recommendation:** Run '/acfs:complete' to properly close this session with all quality gates.
"

    json_content=$(printf '%s' "$OUTPUT_TEXT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read())[1:-1])')

    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": "${json_content}"
  }
}
EOF
fi

exit 0
