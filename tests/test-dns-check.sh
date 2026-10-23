#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/dns-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
CALLS="$TEST_DIR/dig-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/dig" <<'MOCK'
#!/usr/bin/env bash

if [[ "$#" -ne 5 || "$1" != "+time=${MOCK_EXPECTED_TIMEOUT:-2}" || "$2" != "+tries=1" || "$3" != "+short" ]]; then
  exit 9
fi

printf '%s %s\n' "$4" "$5" >> "$MOCK_DIG_LOG"

case "$4 $5" in
  'found.test A') printf '%s\n' '192.0.2.1' '192.0.2.2' ;;
  'found.test AAAA') printf '%s\n' '2001:db8::1' ;;
  'empty.test A') exit 0 ;;
  'error.test A') exit 9 ;;
  *) exit 9 ;;
esac
MOCK

chmod +x "$MOCK_DIR/dig"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_DIG_LOG="$CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check found.test) ||
  fail "Valid A records should succeed"

EXPECTED=$'[FOUND] found.test A\n192.0.2.1\n192.0.2.2'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "A records not displayed correctly"

OUTPUT=$(DNS_TYPE=AAAA run_check found.test) ||
  fail "AAAA records should succeed"

[[ "$OUTPUT" == $'[FOUND] found.test AAAA\n2001:db8::1' ]] ||
  fail "AAAA records not displayed correctly"

OUTPUT=$(DNS_TIMEOUT=5 MOCK_EXPECTED_TIMEOUT=5 run_check found.test) ||
  fail "Custom DNS timeout should succeed"

[[ "$OUTPUT" == *'[FOUND] found.test A'* ]] ||
  fail "Custom DNS timeout not applied"

if OUTPUT=$(run_check found.test empty.test error.test found.test); then
  fail "Mixed DNS results should return failure"
fi

[[ "$OUTPUT" == *'[MISSING] No A records found for empty.test'* ]] ||
  fail "Missing record message incorrect"

[[ "$OUTPUT" == *'[ERROR] DNS lookup failed for error.test'* ]] ||
  fail "Failed lookup message incorrect"

[[ "$(cat "$CALLS")" == *$'error.test A\nfound.test A' ]] ||
  fail "DNS checks should continue after failure"

: > "$CALLS"

for DOMAIN in '' '-evil.test' 'two words' 'a..test' '@other.test'; do
  if OUTPUT=$(run_check "$DOMAIN"); then
    fail "Invalid domain '$DOMAIN' should fail"
  fi

  [[ "$OUTPUT" == *'[INVALID] Invalid domain:'* ]] ||
    fail "Invalid domain message incorrect"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid domains should not invoke dig"

if OUTPUT=$(run_check 2>&1); then
  fail "No domain should fail"
fi

[[ "$OUTPUT" == Usage:* ]] ||
  fail "Missing domain usage message incorrect"

for TYPE in '' abc PTR AXFR a; do
  if OUTPUT=$(DNS_TYPE="$TYPE" run_check found.test 2>&1); then
    fail "Invalid DNS_TYPE '$TYPE' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] DNS_TYPE must be A, AAAA, CNAME, MX, NS or TXT'* ]] ||
    fail "DNS_TYPE error missing"
done

for TIMEOUT in '' 0 -1 abc 31 05; do
  if OUTPUT=$(DNS_TIMEOUT="$TIMEOUT" run_check found.test 2>&1); then
    fail "Invalid DNS_TIMEOUT '$TIMEOUT' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] DNS_TIMEOUT must be an integer between 1 and 30'* ]] ||
    fail "DNS_TIMEOUT error missing"
done

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" found.test 2>&1); then
  fail "Missing dig should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: dig'* ]] ||
  fail "Missing dig error missing"

echo '[ OK ] dns-check.sh tests passed'
