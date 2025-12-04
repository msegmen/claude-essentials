#!/usr/bin/env bash
# Extract and group stack traces from log files
# Usage: extract-stack-traces.sh <log-file> [pattern]
# Examples:
#   extract-stack-traces.sh app.log                    # Auto-detect traces
#   extract-stack-traces.sh app.log "NullPointer"      # Filter by pattern
#   extract-stack-traces.sh app.log "Traceback"        # Python tracebacks

set -euo pipefail

log_file="${1:-}"
filter_pattern="${2:-}"

if [[ -z "$log_file" ]]; then
    echo "Usage: extract-stack-traces.sh <log-file> [pattern]" >&2
    exit 1
fi

if [[ ! -f "$log_file" ]]; then
    echo "Error: File not found: $log_file" >&2
    exit 1
fi

# Common stack trace markers
# - Java: "at " prefix, "Exception", "Error"
# - Python: "Traceback", "File \"", indented lines
# - Node.js: "at " prefix, "Error:"
# - Go: "panic:", "goroutine"

extract_traces() {
    awk '
    BEGIN { in_trace = 0; trace = ""; count = 0 }

    # Start of trace markers
    /Exception|Error:|Traceback|panic:|goroutine [0-9]+ \[/ {
        if (in_trace && trace != "") {
            traces[trace]++
        }
        in_trace = 1
        trace = $0 "\n"
        next
    }

    # Continuation lines (indented or "at " prefix)
    in_trace && /^[[:space:]]+(at |File "|[A-Za-z0-9_.$]+\()/ {
        trace = trace $0 "\n"
        next
    }

    # End of trace (non-indented line that is not a continuation)
    in_trace && !/^[[:space:]]/ && !/^$/ {
        if (trace != "") {
            traces[trace]++
        }
        in_trace = 0
        trace = ""
    }

    END {
        if (in_trace && trace != "") {
            traces[trace]++
        }

        # Sort by count and print
        n = asorti(traces, sorted)
        for (i = n; i >= 1; i--) {
            key = sorted[i]
            printf "=== Count: %d ===\n%s\n", traces[key], key
        }
    }
    ' "$log_file"
}

# Apply filter if provided
if [[ -n "$filter_pattern" ]]; then
    extract_traces | grep -A 50 "$filter_pattern" | head -200
else
    extract_traces | head -500
fi
