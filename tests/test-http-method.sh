#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/http-health-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
CALLS="$TEST_DIR/curl-args.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/curl" <<'MOCK'
#!/usr/bin/env bash

printf '%s\n' "$@" > "$MOCK_CURL_ARGS"
printf '200'
MOCK

chmod +x "$MOCK_DIR/curl"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_CURL_ARGS="$CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check https://example.test) ||
  fail "Default GET request should succeed"

[[ "$OUTPUT" == '[ OK ] https://example.test returned HTTP 200' ]] ||
  fail "Default GET output incorrect"

EXPECTED_GET=$'--silent\n--output\n/dev/null\n--write-out\n%{http_code}\n--max-time\n5\n--\nhttps://example.test'

[[ "$(cat "$CALLS")" == "$EXPECTED_GET" ]] ||
  fail "Default request arguments changed"

OUTPUT=$(HTTP_METHOD=HEAD run_check https://example.test) ||
  fail "HEAD request should succeed"

[[ "$OUTPUT" == '[ OK ] https://example.test returned HTTP 200' ]] ||
  fail "HEAD request output incorrect"

EXPECTED_HEAD=$'--silent\n--output\n/dev/null\n--write-out\n%{http_code}\n--max-time\n5\n--head\n--\nhttps://example.test'

[[ "$(cat "$CALLS")" == "$EXPECTED_HEAD" ]] ||
  fail "HEAD option was not passed to curl"

for METHOD in '' POST PUT PATCH DELETE get head; do
  : > "$CALLS"

  if OUTPUT=$(HTTP_METHOD="$METHOD" run_check https://example.test 2>&1); then
    fail "Invalid HTTP_METHOD '$METHOD' should fail"
  fi

  [[ "$OUTPUT" == '[ERROR] HTTP_METHOD must be GET or HEAD' ]] ||
    fail "Invalid HTTP method message incorrect"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid HTTP method should not invoke curl"
done

echo '[ OK ] HTTP method tests passed'
