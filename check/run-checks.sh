#!/usr/bin/env bash
# Usage: run-checks.sh --mode {plan|diff} [plan-path]
#
# Runs review checks in parallel using claude -p.
# Auto-discovers the review prompt and relevant checks from the repo root.
# Progress lines stream to stdout as each check completes.
# Full detailed results are written to /tmp/check-results.txt.
#
# Modes:
#   --mode plan <plan-path>  Review an implementation plan before coding
#   --mode diff              Review the current git diff before pushing
#
# IMPORTANT: Each `claude -p` call uses `< /dev/null` to detach stdin.
# Without this, claude hangs when spawned from within a Claude Code session
# (the PTY stdin inheritance causes it to block on terminal detection).

set -uo pipefail

# Bypass the nested-session guard
unset CLAUDECODE

# --- Parse arguments ---
MODE=""
PLAN=""

if [[ $# -lt 2 ]]; then
  echo "Usage: run-checks.sh --mode {plan|diff} [plan-path]" >&2
  exit 1
fi

if [[ "$1" != "--mode" ]]; then
  echo "Expected --mode as first argument" >&2
  exit 1
fi

MODE="$2"
shift 2

case "$MODE" in
  plan)
    if [[ $# -lt 1 ]]; then
      echo "Plan mode requires a plan file path" >&2
      exit 1
    fi
    PLAN="$1"
    if [[ ! -f "$PLAN" ]]; then
      echo "Plan file not found: $PLAN" >&2
      exit 1
    fi
    ;;
  diff)
    ;;
  *)
    echo "Unknown mode: $MODE (expected plan or diff)" >&2
    exit 1
    ;;
esac

# Auto-discover paths relative to this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)"

if [[ -z "$REPO_ROOT" ]]; then
  echo "Could not determine repo root from $SCRIPT_DIR" >&2
  exit 1
fi

# Select the correct review prompt
REVIEW_PROMPT="$SCRIPT_DIR/references/review-prompt-${MODE}.md"

if [[ ! -f "$REVIEW_PROMPT" ]]; then
  echo "Review prompt not found: $REVIEW_PROMPT" >&2
  exit 1
fi

# For diff mode, gather the diff and commit log
if [[ "$MODE" == "diff" ]]; then
  git -C "$REPO_ROOT" diff main...HEAD | head -3000 > /tmp/check-diff.patch
  # If the main...HEAD diff is empty, try staged + unstaged
  if [[ ! -s /tmp/check-diff.patch ]]; then
    { git -C "$REPO_ROOT" diff --cached; git -C "$REPO_ROOT" diff; } | head -3000 > /tmp/check-diff.patch
  fi
  if [[ ! -s /tmp/check-diff.patch ]]; then
    echo "No changes found to check." >&2
    exit 1
  fi
  git -C "$REPO_ROOT" log main..HEAD --oneline > /tmp/check-log.txt 2>/dev/null || true
fi

CHECKS_DIR="$REPO_ROOT/.continue/checks"

# Review-relevant checks (skip action-only checks like ai-merge, pr-screenshots, etc.)
REVIEW_CHECKS=(
  architecture-boundaries
  code-conventions
  database-migrations
  security
  telemetry-integrity
  test-quality
  typeorm-cascade-check
  terraform-env-vars
  mobile-layout
)

# Filter to only checks that exist
CHECK_FILES=()
for name in "${REVIEW_CHECKS[@]}"; do
  f="$CHECKS_DIR/$name.md"
  if [[ -f "$f" ]]; then
    CHECK_FILES+=("$f")
  fi
done

if [[ ${#CHECK_FILES[@]} -eq 0 ]]; then
  echo "No matching checks found in $CHECKS_DIR" >&2
  exit 1
fi

RESULTS_DIR=$(mktemp -d)
RESULTS_FILE="/tmp/check-results.txt"
PIDS=()
NAMES=()
START_TIME=$SECONDS

echo "Running ${#CHECK_FILES[@]} checks in parallel (${MODE} mode)..."

for check in "${CHECK_FILES[@]}"; do
  name=$(basename "$check" .md)
  NAMES+=("$name")

  if [[ "$MODE" == "plan" ]]; then
    PROMPT="Review the implementation plan at $PLAN against the check at $check.
Read your detailed review instructions from: $REVIEW_PROMPT"
  else
    PROMPT="Review the code diff against the check at $check.
Read your detailed review instructions from: $REVIEW_PROMPT"
  fi

  claude -p \
    --model haiku \
    --no-session-persistence \
    --allowedTools "Read Glob Grep" \
    --permission-mode bypassPermissions \
    "$PROMPT" \
    < /dev/null > "$RESULTS_DIR/$name.txt" 2>&1 &
  PIDS+=($!)
done

# Poll for completed checks every 2 seconds
TOTAL=${#NAMES[@]}
DONE=0
# Parallel array: 0 = pending, 1 = reported
REPORTED=()
for (( j=0; j<TOTAL; j++ )); do REPORTED+=(0); done

while [[ $DONE -lt $TOTAL ]]; do
  sleep 2
  for i in "${!NAMES[@]}"; do
    # Skip already-reported checks
    [[ "${REPORTED[$i]}" -eq 1 ]] && continue

    pid="${PIDS[$i]}"

    # Check if process has exited
    if ! kill -0 "$pid" 2>/dev/null; then
      name="${NAMES[$i]}"
      elapsed=$(( SECONDS - START_TIME ))
      REPORTED[$i]=1
      ((DONE++)) || true

      # Determine PASS/FAIL from result content
      result_text=$(cat "$RESULTS_DIR/$name.txt" 2>/dev/null || echo "")
      if echo "$result_text" | grep -qi "FAIL"; then
        verdict="FAIL"
        symbol="✗"
      else
        verdict="PASS"
        symbol="✓"
      fi

      echo "  ${symbol} ${name} — ${verdict} (${elapsed}s)  [${DONE}/${TOTAL}]"
    fi
  done
done

echo "All $TOTAL checks complete."

# Write full detailed results to file
> "$RESULTS_FILE"
for name in "${NAMES[@]}"; do
  echo "=== $name ===" >> "$RESULTS_FILE"
  cat "$RESULTS_DIR/$name.txt" >> "$RESULTS_FILE"
  echo "" >> "$RESULTS_FILE"
done

echo ""
echo "Full results written to $RESULTS_FILE"

rm -rf "$RESULTS_DIR"
