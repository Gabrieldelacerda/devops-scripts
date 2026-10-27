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

FOLLOW=0

for ARG in "$@"; do
  if [[ "$ARG" == "--location" ]]; then
    FOLLOW=1
  fi
done

if [[ "$FOLLOW" == "1" ]]; then
  printf '200'
else
  printf '301'
fi
MOCK

chmod +x "$MOCK_DIR/curl"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_CURL_ARGS="$CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

if OUTPUT=$(run_check https://redirect.test); then
  fail "Redirects should not be followed by default"
fi

[[ "$OUTPUT" == '[ALERT] https://redirect.test returned HTTP 301 (expected 200)' ]] ||
  fail "Default redirect handling is incorrect"

if grep -Fqx -- '--location' "$CALLS"; then
  fail "Default requests should not use --location"
fi

OUTPUT=$(HTTP_FOLLOW_REDIRECTS=1 run_check https://redirect.test) ||
  fail "Following redirects should succeed"

[[ "$OUTPUT" == '[ OK ] https://redirect.test returned HTTP 200' ]] ||
  fail "Redirect result is incorrect"

grep -Fqx -- '--location' "$CALLS" ||
  fail "The --location option was not passed to curl"

OUTPUT=$(HTTP_FOLLOW_REDIRECTS=1 HTTP_METHOD=HEAD run_check https://redirect.test) ||
  fail "HEAD requests should support redirects"

grep -Fqx -- '--head' "$CALLS" ||
  fail "HEAD option missing"

grep -Fqx -- '--location' "$CALLS" ||
  fail "Redirect option missing for HEAD requests"

for VALUE in '' 2 -1 true yes 01; do
  : > "$CALLS"

  if OUTPUT=$(HTTP_FOLLOW_REDIRECTS="$VALUE" run_check https://redirect.test 2>&1); then
    fail "Invalid redirect setting '$VALUE' should fail"
  fi

  [[ "$OUTPUT" == '[ERROR] HTTP_FOLLOW_REDIRECTS must be 0 or 1' ]] ||
    fail "Invalid redirect setting produced the wrong message"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid redirect setting should not invoke curl"
done

echo '[ OK ] HTTP redirect tests passed'
