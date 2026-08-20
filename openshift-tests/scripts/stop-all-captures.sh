#!/usr/bin/bash
# Stop all capture processes started by run-all-captures.sh.
# Usage: stop-all-captures.sh [timestamp]
#   If timestamp is omitted, kills the most recent capture-pids-*.txt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${SCRATCH_ROOT}/runs"

if [[ -n "${1:-}" ]]; then
    PID_FILE="${LOG_DIR}/capture-pids-${1}.txt"
else
    PID_FILE=$(ls -t "${LOG_DIR}"/capture-pids-*.txt 2>/dev/null | head -1)
fi

if [[ -z "${PID_FILE}" ]] || [[ ! -f "${PID_FILE}" ]]; then
    echo "No capture PID file found. Specify timestamp or run run-all-captures.sh first."
    exit 1
fi

echo "Stopping captures from ${PID_FILE}"
while read -r p; do
    [[ -z "$p" ]] && continue
    if kill "$p" 2>/dev/null; then
        echo "  killed PID $p"
    fi
done < "${PID_FILE}"
echo "Done."
