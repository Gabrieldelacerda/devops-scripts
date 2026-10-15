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

# Test 1: Remove old .log files, preserve recent and unrelated files.
echo "old log" > "$LOG_DIR/old.log"
echo "recent log" > "$LOG_DIR/recent.log"
echo "other file" > "$LOG_DIR/old.txt"

touch -d "5 days ago" "$LOG_DIR/old.log"
touch -d "1 hour ago" "$LOG_DIR/recent.log"
touch -d "5 days ago" "$LOG_DIR/old.txt"

bash "$SCRIPT" "$LOG_DIR" 1 >/dev/null ||
  fail "Cleanup should succeed for a valid directory"

[[ ! -f "$LOG_DIR/old.log" ]] ||
  fail "Old log file was not removed"

[[ -f "$LOG_DIR/recent.log" ]] ||
  fail "Recent log file should be preserved"

[[ -f "$LOG_DIR/old.txt" ]] ||
  fail "Files without the .log extension should be preserved"

# Test 2: Reject a nonexistent directory.
if bash "$SCRIPT" "$TEST_DIR/missing" 1 >/dev/null 2>&1; then
  fail "Nonexistent directory should return an error"
fi

# Test 3: Reject an invalid retention period.
if bash "$SCRIPT" "$LOG_DIR" invalid >/dev/null 2>&1; then
  fail "Invalid retention period should return an error"
fi

# Test 4: Report failures from the find command.
cat > "$MOCK_DIR/find" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF

chmod +x "$MOCK_DIR/find"

if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" "$LOG_DIR" 1 2>&1); then
  fail "A failed find command should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Log cleanup failed"* ]] ||
  fail "The script should report the find failure"

echo "[ OK ] log-cleanup.sh tests passed"
