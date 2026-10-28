#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/connectivity-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
CALLS="$TEST_DIR/ping-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/ping" <<'MOCK'
#!/usr/bin/env bash

if [[ "$#" -ne 5 || "$1" != "-c" || "$2" != "${MOCK_EXPECTED_COUNT:-1}" || "$3" != "-W" || "$4" != "${MOCK_EXPECTED_TIMEOUT:-2}" ]]; then
  exit 9
fi

printf '%s\n' "$5" >> "$MOCK_PING_LOG"

case "$5" in
  reachable.test|8.8.8.8|1.1.1.1|github.com) exit 0 ;;
  unreachable.test) exit 1 ;;
  error.test)
    echo 'Temporary name resolution failure' >&2
    exit 2
    ;;
  *) exit 9 ;;
esac
MOCK

chmod +x "$MOCK_DIR/ping"

run_check() {
  MOCK_PING_LOG="$CALLS" PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check reachable.test) ||
  fail "Reachable host should succeed"

[[ "$OUTPUT" == '[REACHABLE] reachable.test' ]] ||
  fail "Reachable host message is incorrect"

OUTPUT=$(PING_TIMEOUT=5 MOCK_EXPECTED_TIMEOUT=5 run_check reachable.test) ||
  fail "Custom ping timeout should succeed"

[[ "$OUTPUT" == '[REACHABLE] reachable.test' ]] ||
  fail "Custom ping timeout produced unexpected output"

OUTPUT=$(PING_COUNT=3 MOCK_EXPECTED_COUNT=3 run_check reachable.test) ||
  fail "Custom ping count should succeed"

[[ "$OUTPUT" == '[REACHABLE] reachable.test' ]] ||
  fail "Custom ping count produced unexpected output"

OUTPUT=$(PING_COUNT=5 PING_TIMEOUT=4 MOCK_EXPECTED_COUNT=5 MOCK_EXPECTED_TIMEOUT=4 run_check reachable.test) ||
  fail "Combined ping settings should succeed"

[[ "$OUTPUT" == '[REACHABLE] reachable.test' ]] ||
  fail "Combined ping settings produced unexpected output"

if OUTPUT=$(run_check unreachable.test); then
  fail "Unreachable host should return failure"
fi

[[ "$OUTPUT" == '[UNREACHABLE] unreachable.test' ]] ||
  fail "Unreachable host message is incorrect"

if OUTPUT=$(run_check error.test); then
  fail "Ping execution error should return failure"
fi

[[ "$OUTPUT" == *'[ERROR] Ping failed for error.test (exit code: 2)'* ]] ||
  fail "Ping execution error was not identified"

[[ "$OUTPUT" == *'[DETAIL] Temporary name resolution failure'* ]] ||
  fail "Ping diagnostic detail was not displayed"

: > "$CALLS"

for INVALID in '' '-f' 'two words'; do
  if OUTPUT=$(run_check "$INVALID"); then
    fail "Invalid host should return failure"
  fi

  [[ "$OUTPUT" == *'[INVALID] Invalid host:'* ]] ||
    fail "Invalid host message was not displayed"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid host was passed to ping"

: > "$CALLS"

if OUTPUT=$(run_check reachable.test '' unreachable.test error.test reachable.test); then
  fail "Mixed results should return failure"
fi

EXPECTED=$'[REACHABLE] reachable.test\n[INVALID] Invalid host: \n[UNREACHABLE] unreachable.test\n[ERROR] Ping failed for error.test (exit code: 2)\n[DETAIL] Temporary name resolution failure\n[REACHABLE] reachable.test'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Mixed results or execution order are incorrect"

EXPECTED_CALLS=$'reachable.test\nunreachable.test\nerror.test\nreachable.test'

[[ "$(cat "$CALLS")" == "$EXPECTED_CALLS" ]] ||
  fail "Valid hosts were not checked in the expected order"

: > "$CALLS"

OUTPUT=$(run_check) ||
  fail "Default connectivity check should succeed"

EXPECTED=$'[REACHABLE] 8.8.8.8\n[REACHABLE] 1.1.1.1\n[REACHABLE] github.com'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Default hosts are incorrect"

[[ "$(wc -l < "$CALLS")" -eq 3 ]] ||
  fail "Default hosts were not all checked"

: > "$CALLS"

for INVALID in '' 0 -2 abc 31 1.5 01; do
  if OUTPUT=$(PING_TIMEOUT="$INVALID" run_check reachable.test 2>&1); then
    fail "Invalid PING_TIMEOUT '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] PING_TIMEOUT must be an integer between 1 and 30'* ]] ||
    fail "Invalid PING_TIMEOUT should produce a clear error"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid timeout should not execute ping"

: > "$CALLS"

for INVALID in '' 0 -1 abc 6 10 01; do
  if OUTPUT=$(PING_COUNT="$INVALID" run_check reachable.test 2>&1); then
    fail "Invalid PING_COUNT '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] PING_COUNT must be an integer between 1 and 5'* ]] ||
    fail "Invalid PING_COUNT should produce a clear error"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid ping count should not execute ping"

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" reachable.test 2>&1); then
  fail "Missing ping should return failure"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: ping'* ]] ||
  fail "Missing ping error message was not displayed"

echo '[ OK ] connectivity-check.sh tests passed'
