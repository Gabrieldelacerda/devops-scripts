#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/http-health-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
CALLS="$TEST_DIR/curl-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/curl" <<'MOCK'
#!/usr/bin/env bash

if [[ "$#" -ne 9 || "$1" != "--silent" || "$2" != "--output" || "$3" != "/dev/null" || "$4" != "--write-out" || "$5" != "%{http_code}" || "$6" != "--max-time" || "$7" != "${MOCK_EXPECTED_TIMEOUT:-5}" || "$8" != "--" ]]; then
  exit 9
fi

printf '%s\n' "$9" >> "$MOCK_CURL_LOG"

case "$9" in
  https://ok.test) printf '200' ;;
  https://redirect.test) printf '301' ;;
  https://created.test) printf '201' ;;
  https://dns-error.test) exit 6 ;;
  https://connection-error.test) exit 7 ;;
  https://offline.test) exit 28 ;;
  https://tls-error.test) exit 35 ;;
  https://certificate-error.test) exit 60 ;;
  https://unknown-error.test) exit 52 ;;
  *) exit 9 ;;
esac
MOCK

chmod +x "$MOCK_DIR/curl"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_CURL_LOG="$CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check https://ok.test) ||
  fail "HTTP 200 should succeed"

[[ "$OUTPUT" == '[ OK ] https://ok.test returned HTTP 200' ]] ||
  fail "Successful response output incorrect"

OUTPUT=$(HTTP_EXPECTED_STATUS=201 run_check https://created.test) ||
  fail "Custom expected status should succeed"

[[ "$OUTPUT" == '[ OK ] https://created.test returned HTTP 201' ]] ||
  fail "Custom status output incorrect"

OUTPUT=$(HTTP_TIMEOUT=9 MOCK_EXPECTED_TIMEOUT=9 run_check https://ok.test) ||
  fail "Custom timeout should succeed"

[[ "$OUTPUT" == '[ OK ] https://ok.test returned HTTP 200' ]] ||
  fail "Custom timeout output incorrect"

if OUTPUT=$(run_check https://redirect.test); then
  fail "Unexpected HTTP status should fail"
fi

[[ "$OUTPUT" == '[ALERT] https://redirect.test returned HTTP 301 (expected 200)' ]] ||
  fail "Unexpected HTTP status message incorrect"

for CASE in \
  'dns-error.test|6|DNS resolution failed' \
  'connection-error.test|7|Connection failed' \
  'offline.test|28|Request timed out' \
  'tls-error.test|35|TLS handshake failed' \
  'certificate-error.test|60|TLS certificate verification failed'; do

  IFS='|' read -r HOST CODE REASON <<< "$CASE"

  if OUTPUT=$(run_check "https://$HOST"); then
    fail "$HOST should return failure"
  fi

  EXPECTED="[ERROR] Request failed for https://$HOST (curl exit code: $CODE: $REASON)"

  [[ "$OUTPUT" == "$EXPECTED" ]] ||
    fail "Incorrect diagnostic for curl exit code $CODE"
done

if OUTPUT=$(run_check https://unknown-error.test); then
  fail "Unknown curl error should fail"
fi

[[ "$OUTPUT" == '[ERROR] Request failed for https://unknown-error.test (curl exit code: 52)' ]] ||
  fail "Unknown curl error should retain its exit code"

: > "$CALLS"

if OUTPUT=$(run_check https://ok.test https://offline.test https://created.test); then
  fail "Mixed results should return failure"
fi

[[ "$OUTPUT" == *'[ OK ] https://ok.test returned HTTP 200'* ]] ||
  fail "Initial successful request missing"

[[ "$OUTPUT" == *'Request timed out'* ]] ||
  fail "Timeout diagnostic missing"

[[ "$OUTPUT" == *'[ALERT] https://created.test returned HTTP 201 (expected 200)'* ]] ||
  fail "Requests should continue after a failure"

EXPECTED_CALLS=$'https://ok.test\nhttps://offline.test\nhttps://created.test'

[[ "$(cat "$CALLS")" == "$EXPECTED_CALLS" ]] ||
  fail "Requests were not executed in the expected order"

: > "$CALLS"

for URL in '' 'ftp://foo.test' 'https://' 'https://two words'; do
  if OUTPUT=$(run_check "$URL"); then
    fail "Invalid URL '$URL' should fail"
  fi

  [[ "$OUTPUT" == *'[INVALID] Invalid HTTP URL:'* ]] ||
    fail "Invalid URL message incorrect"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid URLs should not reach curl"

if OUTPUT=$(run_check 2>&1); then
  fail "Missing URL should fail"
fi

[[ "$OUTPUT" == Usage:* ]] ||
  fail "Missing URL usage message incorrect"

for CODE in '' 0 abc 99 600 2000; do
  if OUTPUT=$(HTTP_EXPECTED_STATUS="$CODE" run_check https://ok.test 2>&1); then
    fail "Invalid HTTP status '$CODE' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] HTTP_EXPECTED_STATUS must be a valid HTTP status code'* ]] ||
    fail "Invalid HTTP status message incorrect"
done

for TIMEOUT in '' 0 -1 abc 31 05; do
  if OUTPUT=$(HTTP_TIMEOUT="$TIMEOUT" run_check https://ok.test 2>&1); then
    fail "Invalid timeout '$TIMEOUT' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] HTTP_TIMEOUT must be an integer between 1 and 30'* ]] ||
    fail "Invalid timeout message incorrect"
done

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" https://ok.test 2>&1); then
  fail "Missing curl should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: curl'* ]] ||
  fail "Missing curl message incorrect"

echo '[ OK ] http-health-check.sh tests passed'
