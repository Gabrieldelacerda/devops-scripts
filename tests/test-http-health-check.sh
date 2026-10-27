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
  https://offline.test) exit 28 ;;
  *) exit 9 ;;
esac
MOCK

chmod +x "$MOCK_DIR/curl"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_CURL_LOG="$CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check https://ok.test) ||
  fail "200 response should succeed"

[[ "$OUTPUT" == '[ OK ] https://ok.test returned HTTP 200' ]] ||
  fail "Successful response output incorrect"

OUTPUT=$(HTTP_EXPECTED_STATUS=201 run_check https://created.test) ||
  fail "Custom expected status should succeed"

[[ "$OUTPUT" == '[ OK ] https://created.test returned HTTP 201' ]] ||
  fail "Custom status output incorrect"

OUTPUT=$(HTTP_TIMEOUT=9 MOCK_EXPECTED_TIMEOUT=9 run_check https://ok.test) ||
  fail "Custom HTTP timeout should succeed"

[[ "$OUTPUT" == '[ OK ] https://ok.test returned HTTP 200' ]] ||
  fail "Custom timeout output incorrect"

if OUTPUT=$(run_check https://ok.test https://redirect.test https://offline.test https://created.test); then
  fail "Mixed responses should return failure"
fi

[[ "$OUTPUT" == *'[ALERT] https://redirect.test returned HTTP 301 (expected 200)'* ]] ||
  fail "Unexpected status not detected"

[[ "$OUTPUT" == *'[ERROR] Request failed for https://offline.test (curl exit code: 28: Request timed out)'* ]] ||
  fail "Request error not detected"

[[ "$OUTPUT" == *'[ALERT] https://created.test returned HTTP 201 (expected 200)'* ]] ||
  fail "Subsequent request not checked"

: > "$CALLS"

for URL in '' 'ftp://foo.test' 'https://' 'https://two words'; do
  if OUTPUT=$(run_check "$URL"); then
    fail "Invalid URL '$URL' should fail"
  fi

  [[ "$OUTPUT" == *'[INVALID] Invalid HTTP URL:'* ]] ||
    fail "Invalid URL output incorrect"
done

[[ ! -s "$CALLS" ]] ||
  fail "Invalid URLs should not invoke curl"

if OUTPUT=$(run_check 2>&1); then
  fail "No URL should fail"
fi

[[ "$OUTPUT" == Usage:* ]] ||
  fail "No URL usage missing"

for CODE in '' 0 abc 99 600 2000; do
  if OUTPUT=$(HTTP_EXPECTED_STATUS="$CODE" run_check https://ok.test 2>&1); then
    fail "Invalid status '$CODE' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] HTTP_EXPECTED_STATUS must be a valid HTTP status code'* ]] ||
    fail "Invalid expected status error missing"
done

for TIMEOUT in '' 0 -1 abc 31 05; do
  if OUTPUT=$(HTTP_TIMEOUT="$TIMEOUT" run_check https://ok.test 2>&1); then
    fail "Invalid timeout '$TIMEOUT' should fail"
  fi

  [[ "$OUTPUT" == *'[ERROR] HTTP_TIMEOUT must be an integer between 1 and 30'* ]] ||
    fail "Invalid timeout error missing"
done

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" https://ok.test 2>&1); then
  fail "Missing curl should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: curl'* ]] ||
  fail "Missing curl error missing"

echo '[ OK ] http-health-check.sh tests passed'
