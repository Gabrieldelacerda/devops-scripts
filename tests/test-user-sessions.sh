#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/user-sessions.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
LIMITED_DIR="$TEST_DIR/limited-bin"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$LIMITED_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

# Mock session commands without accessing real login records.
for CMD in who w last lastb; do
  cat > "$MOCK_DIR/$CMD" <<'EOF'
#!/bin/sh
printf 'mock-%s %s\n' "${0##*/}" "$*"
EOF
  chmod +x "$MOCK_DIR/$CMD"
done

# Test 1: Valid limit and expected commands.
OUTPUT=$(PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT" 3) ||
  fail "Valid session check should succeed"

[[ "$OUTPUT" == *"mock-who"* ]] ||
  fail "Active sessions were not checked"

[[ "$OUTPUT" == *"mock-w "* ]] ||
  fail "Logged-in users were not checked"

[[ "$OUTPUT" == *"mock-last -n 3"* ]] ||
  fail "Login history limit was not applied"

[[ "$OUTPUT" == *"mock-lastb -n 3"* ]] ||
  fail "Failed login history limit was not applied"

# Test 2: Invalid limits must fail.
for INVALID in 0 -1 abc 1.5; do
  if PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT" "$INVALID" >/dev/null 2>&1; then
    fail "Invalid limit '$INVALID' should fail"
  fi
done

# Test 3: Default limit should be 5.
OUTPUT=$(PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT") ||
  fail "Default limit should succeed"

[[ "$OUTPUT" == *"mock-last -n 5"* ]] ||
  fail "Default login history limit should be 5"

# Test 4: Missing optional commands should produce warnings.
cp "$MOCK_DIR/who" "$MOCK_DIR/w" "$LIMITED_DIR/"

OUTPUT=$(PATH="$LIMITED_DIR" "$BASH_BIN" "$SCRIPT" 2) ||
  fail "Missing optional commands should not fail the script"

[[ "$OUTPUT" == *"'last' command is not available"* ]] ||
  fail "Missing last command should produce a warning"

[[ "$OUTPUT" == *"'lastb' command is not available"* ]] ||
  fail "Missing lastb command should produce a warning"

echo "[ OK ] user-sessions.sh tests passed"
