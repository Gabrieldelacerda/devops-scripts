#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/cpu-check.sh"

TEST_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
STAT_FILE="$TEST_DIR/stat"
NEXT_STAT="$TEST_DIR/next-stat"
mkdir -p "$MOCK_DIR"

cat > "$MOCK_DIR/sleep" <<'MOCK'
#!/usr/bin/env bash

if [[ "${MOCK_SLEEP_FAILURE:-}" == "1" ]]; then
  exit 1
fi

cp -- "$MOCK_NEXT_STAT" "$CPU_STAT_FILE"
MOCK

chmod +x "$MOCK_DIR/sleep"

fail() {
  echo "[FAIL] $1"
  exit 1
}

check_case() {
  local name="$1"
  local threshold="$2"
  local before="$3"
  local after="$4"
  local expected_status="$5"
  local expected_output="$6"
  local output status

  printf '%s\n' "$before" > "$STAT_FILE"
  printf '%s\n' "$after" > "$NEXT_STAT"

  if output=$(PATH="$MOCK_DIR:$PATH" CPU_STAT_FILE="$STAT_FILE" MOCK_NEXT_STAT="$NEXT_STAT" THRESHOLD="$threshold" bash "$SCRIPT" 2>&1); then
    status=0
  else
    status=$?
  fi

  if [[ "$status" -ne "$expected_status" || "$output" != "$expected_output" ]]; then
    echo "[FAIL] $name"
    echo "Expected: $expected_output (exit $expected_status)"
    echo "Actual: $output (exit $status)"
    exit 1
  fi
}

BEFORE="cpu 100 0 50 700 100 0 0 50 0 0"
AFTER="cpu 120 0 60 760 100 0 0 60 0 0"

check_case "Healthy CPU" 80 "$BEFORE" "$AFTER" 0 "[ OK ] CPU usage is at 40%"
check_case "Threshold boundary" 40 "$BEFORE" "$AFTER" 1 "[ALERT] CPU usage is at 40%"
check_case "Zero threshold" 0 "$BEFORE" "$AFTER" 1 "[ALERT] CPU usage is at 40%"
check_case "Threshold 100" 100 "$BEFORE" "$AFTER" 0 "[ OK ] CPU usage is at 40%"
check_case "Invalid threshold" abc "$BEFORE" "$AFTER" 1 "[ERROR] THRESHOLD must be an integer between 0 and 100"
check_case "Threshold above 100" 101 "$BEFORE" "$AFTER" 1 "[ERROR] THRESHOLD must be an integer between 0 and 100"
check_case "Malformed CPU counters" 80 "cpu 100 bad 50 700 100 0 0 50" "$AFTER" 1 "[ERROR] Could not read CPU statistics"
check_case "Malformed CPU label" 80 "notcpu 100 0 50 700 100 0 0 50" "$AFTER" 1 "[ERROR] Could not read CPU statistics"
check_case "No CPU counter changes" 80 "$BEFORE" "$BEFORE" 1 "[ERROR] Invalid CPU statistics"
check_case "Decreasing idle counter" 80 "$BEFORE" "cpu 250 0 50 650 100 0 0 50 0 0" 1 "[ERROR] Invalid CPU statistics"
check_case "Idle growth exceeds total" 80 "$BEFORE" "cpu 80 0 50 820 100 0 0 50 0 0" 1 "[ERROR] Invalid CPU statistics"

printf '%s\n' "$BEFORE" > "$STAT_FILE"
printf '%s\n' "$AFTER" > "$NEXT_STAT"

if OUTPUT=$(PATH="$MOCK_DIR:$PATH" CPU_STAT_FILE="$STAT_FILE" MOCK_NEXT_STAT="$NEXT_STAT" MOCK_SLEEP_FAILURE=1 THRESHOLD=80 bash "$SCRIPT" 2>&1); then
  fail "Failed CPU sampling should return an error"
fi

[[ "$OUTPUT" == "[ERROR] CPU sampling failed" ]] ||
  fail "Failed CPU sampling should explain the error"

echo "[ OK ] cpu-check.sh tests passed"
