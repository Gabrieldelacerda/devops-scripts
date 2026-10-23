#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/process-monitor.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$TEST_DIR/ps" <<'MOCK'
#!/usr/bin/env bash

case "$*" in
  *--sort=-%cpu) TYPE=cpu ;;
  *--sort=-%mem) TYPE=memory ;;
  *) exit 1 ;;
esac

if [[ "${MOCK_PS_FAILURE:-}" == "$TYPE" ]]; then
  echo "Simulated process query failure" >&2
  exit 1
fi

if [[ "${MOCK_PS_OUTPUT:-}" == "$TYPE-empty" ]]; then
  exit 0
fi

printf '%s\n' 'USER PID %CPU %MEM COMMAND'

if [[ "${MOCK_PS_OUTPUT:-}" == "$TYPE-header" ]]; then
  exit 0
fi

if [[ "$TYPE" == cpu ]]; then
  printf '%s\n' \
    'runner 101 75.0 1.0 cpu_worker' \
    'runner 102 1.0 85.0 memory_worker'
else
  printf '%s\n' \
    'runner 102 1.0 85.0 memory_worker' \
    'runner 101 75.0 1.0 cpu_worker'
fi
MOCK

chmod +x "$TEST_DIR/ps"

if ! OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT" 1); then
  fail "Valid process limit should succeed"
fi

EXPECTED=$(cat <<'EXPECTED_OUTPUT'
Top 1 processes by CPU usage:
USER PID %CPU %MEM COMMAND
runner 101 75.0 1.0 cpu_worker

Top 1 processes by memory usage:
USER PID %CPU %MEM COMMAND
runner 102 1.0 85.0 memory_worker
EXPECTED_OUTPUT
)

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Process sorting or output limit is incorrect"

OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT" 08) ||
  fail "Leading-zero decimal limit should succeed"

[[ "$OUTPUT" == *'Top 8 processes by CPU usage:'* ]] ||
  fail "Leading-zero limit was not interpreted as decimal"

for INVALID in '' 0 -1 abc 1.5 1001; do
  if OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT" "$INVALID" 2>&1); then
    fail "Invalid limit '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == Usage:* ]] ||
    fail "Invalid limit '$INVALID' should show usage"
done

if OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT" 1 extra 2>&1); then
  fail "Extra arguments should be rejected"
fi

[[ "$OUTPUT" == Usage:* ]] ||
  fail "Extra arguments should show usage"

OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT") ||
  fail "Default process limit should succeed"

[[ "$OUTPUT" == *'Top 5 processes by CPU usage:'* ]] ||
  fail "Default limit should be 5"

for FAILURE in cpu memory; do
  if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_PS_FAILURE="$FAILURE" bash "$SCRIPT" 1 2>&1); then
    fail "A failed $FAILURE query should return an error"
  fi

  if [[ "$FAILURE" == cpu ]]; then
    EXPECTED_ERROR="[ERROR] Failed to retrieve process list for CPU usage"
  else
    EXPECTED_ERROR="[ERROR] Failed to retrieve process list for memory usage"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "A failed $FAILURE query should explain the error"
done

for TYPE in cpu memory; do
  if [[ "$TYPE" == cpu ]]; then
    LABEL="CPU"
  else
    LABEL="memory"
  fi

  for MODE in empty header; do
    if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_PS_OUTPUT="$TYPE-$MODE" bash "$SCRIPT" 1 2>&1); then
      fail "$TYPE $MODE output should return an error"
    fi

    [[ "$OUTPUT" == *"[ERROR] No process data returned for $LABEL usage"* ]] ||
      fail "Missing process data should produce an error"
  done
done

echo "[ OK ] process-monitor.sh tests passed"
