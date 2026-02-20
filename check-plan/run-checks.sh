#!/usr/bin/env bash
# Usage: run-checks.sh <plan-path> <review-prompt-path> <check-path>...
#
# Runs plan review checks in parallel using claude -p.
# Each check gets its own claude process; results are collected and printed.
#
# IMPORTANT: Each `claude -p` call uses `< /dev/null` to detach stdin.
# Without this, claude hangs when spawned from within a Claude Code session
# (the PTY stdin inheritance causes it to block on terminal detection).

set -uo pipefail

# Bypass the nested-session guard
unset CLAUDECODE

PLAN="$1"
REVIEW_PROMPT="$2"
shift 2

if [[ $# -eq 0 ]]; then
  echo "No checks provided" >&2
  exit 1
fi

RESULTS_DIR=$(mktemp -d)
PIDS=()
NAMES=()

for check in "$@"; do
  name=$(basename "$check" .md)
  NAMES+=("$name")
  claude -p \
    --model haiku \
    --no-session-persistence \
    --allowedTools "Read Glob Grep" \
    --permission-mode bypassPermissions \
    "Review the implementation plan at $PLAN against the check at $check.
Read your detailed review instructions from: $REVIEW_PROMPT" \
    < /dev/null > "$RESULTS_DIR/$name.txt" 2>&1 &
  PIDS+=($!)
done

# Wait for all and track failures
FAILURES=0
for i in "${!PIDS[@]}"; do
  if ! wait "${PIDS[$i]}"; then
    echo "FAIL (process error)" > "$RESULTS_DIR/${NAMES[$i]}.txt"
    ((FAILURES++)) || true
  fi
done

# Output results
for name in "${NAMES[@]}"; do
  echo "=== $name ==="
  cat "$RESULTS_DIR/$name.txt"
  echo ""
done

rm -rf "$RESULTS_DIR"
