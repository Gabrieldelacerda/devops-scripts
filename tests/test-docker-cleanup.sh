#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$PROJECT_DIR/docker-cleanup.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_PATH="$TEST_DIR/no-docker"
LOG="$TEST_DIR/docker-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_PATH"

fail() {
  echo "[FAIL] $1"
  exit 1
}

# Mock Docker to avoid changing real Docker resources.
cat > "$MOCK_DIR/docker" <<'EOF'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "$MOCK_DOCKER_LOG"

if [[ "${MOCK_DOCKER_FAIL_STEP:-}" == "$*" ]]; then
  exit 1
fi

case "$*" in
  info|"container prune -f"|"image prune -f"|"volume prune -f")
    exit 0
    ;;
  *)
    exit 2
    ;;
esac
EOF

chmod +x "$MOCK_DIR/docker"

run_script() {
  local reply="$1"
  local failed_step="${2:-}"

  printf '%s\n' "$reply" |
    PATH="$MOCK_DIR:$PATH" \
    MOCK_DOCKER_LOG="$LOG" \
    MOCK_DOCKER_FAIL_STEP="$failed_step" \
    "$BASH_BIN" "$SCRIPT"
}

# Test 1: Docker executable is missing.
if OUTPUT=$(PATH="$EMPTY_PATH" "$BASH_BIN" "$SCRIPT" 2>&1); then
  fail "Missing Docker should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Docker is not installed"* ]] ||
  fail "Missing Docker error message not found"

# Test 2: Docker daemon is unavailable.
: > "$LOG"

if OUTPUT=$(run_script "y" "info" 2>&1); then
  fail "Unavailable Docker daemon should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Docker daemon is not available"* ]] ||
  fail "Docker daemon error message not found"

[[ "$(cat "$LOG")" == "info" ]] ||
  fail "Cleanup must not run when Docker daemon is unavailable"

# Test 3: User cancels cleanup.
: > "$LOG"

OUTPUT=$(run_script "n") ||
  fail "Cancelled cleanup should exit successfully"

[[ "$OUTPUT" == *"Cleanup cancelled."* ]] ||
  fail "Cancellation message not found"

[[ "$(cat "$LOG")" == "info" ]] ||
  fail "Cancelled cleanup must not prune resources"

# Test 4: Successful cleanup runs commands in order.
: > "$LOG"

OUTPUT=$(run_script "y") ||
  fail "Confirmed cleanup should succeed"

[[ "$OUTPUT" == *"[ OK ] Docker cleanup completed successfully"* ]] ||
  fail "Success message not found"

EXPECTED_CALLS=$'info\ncontainer prune -f\nimage prune -f\nvolume prune -f'

[[ "$(cat "$LOG")" == "$EXPECTED_CALLS" ]] ||
  fail "Docker cleanup commands were not executed in the expected order"

# Test 5: Failures stop the cleanup immediately.
for FAILED_STEP in \
  "container prune -f" \
  "image prune -f" \
  "volume prune -f"; do

  : > "$LOG"

  if OUTPUT=$(run_script "y" "$FAILED_STEP" 2>&1); then
    fail "Failure in $FAILED_STEP should return an error"
  fi

  case "$FAILED_STEP" in
    "container prune -f")
      EXPECTED_ERROR="Failed to remove stopped containers"
      EXPECTED_CALLS=$'info\ncontainer prune -f'
      ;;
    "image prune -f")
      EXPECTED_ERROR="Failed to remove unused images"
      EXPECTED_CALLS=$'info\ncontainer prune -f\nimage prune -f'
      ;;
    "volume prune -f")
      EXPECTED_ERROR="Failed to remove dangling volumes"
      EXPECTED_CALLS=$'info\ncontainer prune -f\nimage prune -f\nvolume prune -f'
      ;;
  esac

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "Expected error message not found for $FAILED_STEP"

  [[ "$(cat "$LOG")" == "$EXPECTED_CALLS" ]] ||
    fail "Cleanup continued incorrectly after $FAILED_STEP failed"
done

echo "[ OK ] docker-cleanup.sh tests passed"
