#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$PROJECT_DIR/log-cleanup.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

LOG_DIR="$TEST_DIR/logs"
MOCK_DIR="$TEST_DIR/mock-bin"

mkdir -p "$LOG_DIR" "$MOCK_DIR"

# Prepare temporary files with different ages.
echo "old log" > "$LOG_DIR/old.log"
echo "recent log" > "$LOG_DIR/recent.log"
echo "other file" > "$LOG_DIR/old.txt"

touch -d "5 days ago" "$LOG_DIR/old.log"
touch -d "1 hour ago" "$LOG_DIR/recent.log"
touch -d "5 days ago" "$LOG_DIR/old.txt"

# Test 1: Dry run must list old logs without deleting anything.
OUTPUT=$(bash "$SCRIPT" "$LOG_DIR" 1 --dry-run) ||
  fail "Dry run should succeed"

[[ "$OUTPUT" == *"$LOG_DIR/old.log"* ]] ||
  fail "Dry run should list the old log"

[[ "$OUTPUT" != *"$LOG_DIR/recent.log"* ]] ||
  fail "Dry run should not list recent logs"

[[ -f "$LOG_DIR/old.log" ]] ||
  fail "Dry run must not delete old logs"

[[ -f "$LOG_DIR/recent.log" ]] ||
  fail "Dry run must preserve recent logs"

[[ "$OUTPUT" == *"no files deleted"* ]] ||
  fail "Dry run confirmation message is missing"

# Test 2: Normal cleanup removes only old .log files.
bash "$SCRIPT" "$LOG_DIR" 1 >/dev/null ||
  fail "Normal cleanup should succeed"

[[ ! -f "$LOG_DIR/old.log" ]] ||
  fail "Old log was not removed"

[[ -f "$LOG_DIR/recent.log" ]] ||
  fail "Recent log should be preserved"

[[ -f "$LOG_DIR/old.txt" ]] ||
  fail "Files without the .log extension should be preserved"

# Test 3: Missing directories must return an error.
if bash "$SCRIPT" "$TEST_DIR/missing" 1 >/dev/null 2>&1; then
  fail "Missing directory should return an error"
fi

# Test 4: Invalid retention periods must be rejected.
if bash "$SCRIPT" "$LOG_DIR" invalid >/dev/null 2>&1; then
  fail "Invalid retention period should return an error"
fi

# Test 5: Unsupported options must be rejected.
if bash "$SCRIPT" "$LOG_DIR" 1 --unknown >/dev/null 2>&1; then
  fail "Unsupported option should return an error"
fi

# Test 6: Failed find commands must return errors.
cat > "$MOCK_DIR/find" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$MOCK_DIR/find"

for MODE in normal dry-run; do
  if [[ "$MODE" == "dry-run" ]]; then
    ARGS=("$LOG_DIR" 1 --dry-run)
  else
    ARGS=("$LOG_DIR" 1)
  fi

  if PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" "${ARGS[@]}" >/dev/null 2>&1; then
    fail "Failed find command should be detected in $MODE mode"
  fi
done

echo "[ OK ] log-cleanup.sh tests passed"
