
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

# Simulate predictable process information.
cat > "$TEST_DIR/ps" <<'MOCK'
#!/usr/bin/env bash

case "$*" in
  *--sort=-%cpu)
    printf '%s\n' \
      'USER PID %CPU %MEM COMMAND' \
      'runner 101 75.0 1.0 cpu_worker' \
      'runner 102 1.0 85.0 memory_worker'
    ;;
  *--sort=-%mem)
    printf '%s\n' \
      'USER PID %CPU %MEM COMMAND' \
      'runner 102 1.0 85.0 memory_worker' \
      'runner 101 75.0 1.0 cpu_worker'
    ;;
  *)
    exit 1
    ;;
esac
MOCK

chmod +x "$TEST_DIR/ps"

# A limit of 1 should return the top process in each category.
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

# Invalid limits must be rejected.
for INVALID in 0 -1 abc 1.5; do
  if OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT" "$INVALID" 2>&1); then
    fail "Invalid limit '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == Usage:* ]] ||
    fail "Invalid limit '$INVALID' should show usage"
done

# The default limit should be 5.
if ! OUTPUT=$(PATH="$TEST_DIR:$PATH" bash "$SCRIPT"); then
  fail "Default process limit should succeed"
fi

[[ "$OUTPUT" == *'Top 5 processes by CPU usage:'* ]] ||
  fail "Default limit should be 5"

echo "[ OK ] process-monitor.sh tests passed"
