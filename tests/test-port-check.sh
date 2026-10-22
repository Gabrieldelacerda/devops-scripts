#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/port-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
CALLS="$TEST_DIR/nc-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/nc" <<'EOF'
#!/usr/bin/env bash

printf '%s %s %s\n' "$1" "$2" "$3" >> "$MOCK_NC_LOG"

if [[ "$#" -ne 3 || "$1" != "-zw${MOCK_EXPECTED_TIMEOUT:-2}" ]]; then
  exit 2
fi

case "$2" in
  example.test|localhost) ;;
  *) exit 2 ;;
esac

case "$3" in
  1|22|80|443|3306|65535) exit 0 ;;
  81) exit 1 ;;
  *) exit 2 ;;
esac
EOF

chmod +x "$MOCK_DIR/nc"

run_check() {
  MOCK_NC_LOG="$CALLS" \
    PATH="$MOCK_DIR:$PATH" \
    "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check example.test 22) ||
  fail "Open port should return success"

[[ "$OUTPUT" == "[OPEN] example.test:22" ]] ||
  fail "Open port message is incorrect"

OUTPUT=$(run_check example.test 1 65535) ||
  fail "Boundary port values should be accepted"

EXPECTED=$'[OPEN] example.test:1\n[OPEN] example.test:65535'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Boundary port results are incorrect"

if OUTPUT=$(run_check example.test 81); then
  fail "Unreachable port should return failure"
fi

[[ "$OUTPUT" == "[UNREACHABLE] example.test:81" ]] ||
  fail "Unreachable port message is incorrect"

for INVALID in 0 65536 abc -1 1.5; do
  : > "$CALLS"

  if OUTPUT=$(run_check example.test "$INVALID"); then
    fail "Invalid port '$INVALID' should return failure"
  fi

  [[ "$OUTPUT" == "[INVALID] Port must be between 1 and 65535: $INVALID" ]] ||
    fail "Invalid port '$INVALID' produced incorrect output"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid port '$INVALID' was passed to nc"
done

: > "$CALLS"

if OUTPUT=$(run_check example.test 22 70000 81 443); then
  fail "Mixed results should return failure"
fi

EXPECTED=$'[OPEN] example.test:22\n[INVALID] Port must be between 1 and 65535: 70000\n[UNREACHABLE] example.test:81\n[OPEN] example.test:443'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Mixed results or execution order are incorrect"

EXPECTED_CALLS=$'-zw2 example.test 22\n-zw2 example.test 81\n-zw2 example.test 443'

[[ "$(cat "$CALLS")" == "$EXPECTED_CALLS" ]] ||
  fail "Valid ports were not checked in the expected order"

: > "$CALLS"

OUTPUT=$(run_check) ||
  fail "Default configuration should succeed"

EXPECTED=$'[OPEN] localhost:22\n[OPEN] localhost:80\n[OPEN] localhost:443\n[OPEN] localhost:3306'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Default host or ports are incorrect"

: > "$CALLS"

OUTPUT=$(CONNECT_TIMEOUT=5 MOCK_EXPECTED_TIMEOUT=5 run_check example.test 443) ||
  fail "Custom timeout should succeed"

[[ "$OUTPUT" == "[OPEN] example.test:443" ]] ||
  fail "Custom timeout produced incorrect output"

[[ "$(cat "$CALLS")" == "-zw5 example.test 443" ]] ||
  fail "Custom timeout was not passed to nc"

for INVALID in 0 31 abc -1 1.5 02; do
  : > "$CALLS"

  if OUTPUT=$(CONNECT_TIMEOUT="$INVALID" run_check example.test 22 2>&1); then
    fail "Invalid timeout '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == "[ERROR] CONNECT_TIMEOUT must be an integer between 1 and 30 seconds" ]] ||
    fail "Invalid timeout '$INVALID' produced incorrect output"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid timeout '$INVALID' reached nc"
done

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" example.test 22 2>&1); then
  fail "Missing nc should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] Required command not found: nc"* ]] ||
  fail "Missing nc error message was not displayed"

echo "[ OK ] port-check.sh tests passed"
