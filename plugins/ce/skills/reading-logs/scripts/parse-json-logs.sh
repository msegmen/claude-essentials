#!/usr/bin/env bash
# Parse JSON/JSONL logs with jq
# Usage: parse-json-logs.sh <log-file> [jq-filter]
# Examples:
#   parse-json-logs.sh app.log                           # Pretty print all
#   parse-json-logs.sh app.log '.level == "error"'       # Filter by level
#   parse-json-logs.sh app.log 'select(.status >= 500)'  # Filter by status

set -euo pipefail

log_file="${1:-}"
jq_filter="${2:-.}"

if [[ -z "$log_file" ]]; then
    echo "Usage: parse-json-logs.sh <log-file> [jq-filter]" >&2
    echo "Examples:" >&2
    echo "  parse-json-logs.sh app.log" >&2
    echo "  parse-json-logs.sh app.log 'select(.level == \"error\")'" >&2
    exit 1
fi

if [[ ! -f "$log_file" ]]; then
    echo "Error: File not found: $log_file" >&2
    exit 1
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 1
fi

# Detect format and process
# Try newline-delimited JSON first (most common for logs)
first_char=$(head -c 1 "$log_file")

if [[ "$first_char" == "[" ]]; then
    # JSON array format
    jq "$jq_filter" "$log_file"
else
    # Newline-delimited JSON (JSONL)
    # Use -c for compact output, handle non-JSON lines gracefully
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines
        [[ -z "$line" ]] && continue

        # Try to parse as JSON, skip if invalid
        if echo "$line" | jq -e . &>/dev/null; then
            echo "$line" | jq "$jq_filter" 2>/dev/null || true
        fi
    done < "$log_file"
fi
