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

for CMD in who w last lastb; do
  cat > "$MOCK_DIR/$CMD" <<'EOF'
#!/bin/sh

NAME=${0##*/}

if [ "${MOCK_FAIL_COMMAND:-}" = "$NAME" ]; then
  echo "Simulated command failure" >&2
  exit 2
fi

printf 'mock-%s %s\n' "$NAME" "$*"
EOF
  chmod +x "$MOCK_DIR/$CMD"
done

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

for INVALID in 0 -1 abc 1.5; do
  if PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT" "$INVALID" >/dev/null 2>&1; then
    fail "Invalid limit '$INVALID' should fail"
  fi
done

OUTPUT=$(PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT") ||
  fail "Default limit should succeed"

[[ "$OUTPUT" == *"mock-last -n 5"* ]] ||
  fail "Default login history limit should be 5"

cp "$MOCK_DIR/who" "$MOCK_DIR/w" "$LIMITED_DIR/"

OUTPUT=$(PATH="$LIMITED_DIR" "$BASH_BIN" "$SCRIPT" 2) ||
  fail "Missing optional commands should not fail the script"

[[ "$OUTPUT" == *"'last' command is not available"* ]] ||
  fail "Missing last command should produce a warning"

[[ "$OUTPUT" == *"'lastb' command is not available"* ]] ||
  fail "Missing lastb command should produce a warning"

for CMD in who w; do
  if OUTPUT=$(PATH="$MOCK_DIR:$PATH" MOCK_FAIL_COMMAND="$CMD" "$BASH_BIN" "$SCRIPT" 2 2>&1); then
    fail "Failed required command '$CMD' should return an error"
  fi

  if [[ "$CMD" == "who" ]]; then
    EXPECTED="[ERROR] Failed to retrieve active sessions (who)"
  else
    EXPECTED="[ERROR] Failed to retrieve logged-in users (w)"
  fi

  [[ "$OUTPUT" == *"$EXPECTED"* ]] ||
    fail "Failed required command '$CMD' should explain the error"
done

for CMD in last lastb; do
  OUTPUT=$(PATH="$MOCK_DIR:$PATH" MOCK_FAIL_COMMAND="$CMD" "$BASH_BIN" "$SCRIPT" 2 2>&1) ||
    fail "Failed optional command '$CMD' should not stop the script"

  if [[ "$CMD" == "last" ]]; then
    EXPECTED="[WARN] Failed to retrieve login history (last)"
    [[ "$OUTPUT" == *"mock-lastb -n 2"* ]] ||
      fail "Failed last command should not prevent checking lastb"
  else
    EXPECTED="[WARN] Failed to retrieve failed login attempts (lastb)"
  fi

  [[ "$OUTPUT" == *"$EXPECTED"* ]] ||
    fail "Failed optional command '$CMD' should produce a warning"
done

echo "[ OK ] user-sessions.sh tests passed"
