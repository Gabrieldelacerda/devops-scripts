#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/uptime-check.sh"

TEST_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$TEST_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$TEST_DIR/nproc" <<'EOF'
#!/usr/bin/env bash

if [[ "${MOCK_FAIL_CMD:-}" == "nproc" ]]; then
  exit 2
fi

if [[ "${MOCK_INVALID_CPUS:-}" == "1" ]]; then
  echo "0"
else
  echo "4"
fi
EOF

cat > "$TEST_DIR/uptime" <<'EOF'
#!/usr/bin/env bash

if [[ "${MOCK_FAIL_CMD:-}" == "uptime" ]]; then
  exit 2
fi

if [[ "${MOCK_EMPTY_UPTIME:-}" == "1" ]]; then
  exit 0
fi

echo "up 1 hour"
EOF

chmod +x "$TEST_DIR/nproc" "$TEST_DIR/uptime"

if ! OUTPUT=$(PATH="$TEST_DIR:$PATH" LOAD_THRESHOLD=999999 bash "$SCRIPT"); then
  fail "Healthy load should return success"
fi

[[ "$OUTPUT" == *"[ OK ] 1-minute load is "* ]] ||
  fail "Expected healthy load output"

[[ "$OUTPUT" == *"(threshold: 999999)"* ]] ||
  fail "Expected correct threshold"

[[ "$OUTPUT" == *"Uptime: up 1 hour"* ]] ||
  fail "Expected uptime output"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" LOAD_THRESHOLD=0 bash "$SCRIPT"); then
  fail "Threshold zero should trigger an alert"
fi

[[ "$OUTPUT" == *"[ALERT] 1-minute load is "* ]] ||
  fail "Expected load average alert"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" LOAD_THRESHOLD=abc bash "$SCRIPT" 2>&1); then
  fail "Invalid threshold should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] LOAD_THRESHOLD must be a non-negative number"* ]] ||
  fail "Expected threshold validation error"

if ! OUTPUT=$(PATH="$TEST_DIR:$PATH" LOAD_THRESHOLD=999999.5 bash "$SCRIPT"); then
  fail "Decimal threshold should be accepted"
fi

[[ "$OUTPUT" == *"(threshold: 999999.5)"* ]] ||
  fail "Expected successful decimal threshold check"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_FAIL_CMD=nproc bash "$SCRIPT" 2>&1); then
  fail "Failed nproc should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Failed to retrieve CPU count"* ]] ||
  fail "Expected CPU retrieval error"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_INVALID_CPUS=1 bash "$SCRIPT" 2>&1); then
  fail "Invalid CPU count should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Invalid CPU count: 0"* ]] ||
  fail "Expected invalid CPU count error"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_FAIL_CMD=uptime bash "$SCRIPT" 2>&1); then
  fail "Failed uptime should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Failed to retrieve system uptime"* ]] ||
  fail "Expected uptime retrieval error"

if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_EMPTY_UPTIME=1 bash "$SCRIPT" 2>&1); then
  fail "Empty uptime should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Failed to retrieve system uptime"* ]] ||
  fail "Expected empty uptime error"

echo "[ OK ] uptime-check.sh tests passed"
