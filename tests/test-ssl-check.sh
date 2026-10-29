#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/ssl-check.sh"

TEST_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
TIMEOUT_CALLS="$TEST_DIR/timeout-calls.log"
BASH_BIN="$(command -v bash)"
mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/timeout" <<'MOCK'
#!/usr/bin/env bash

if [[ "$#" -lt 2 || "$1" != "${MOCK_EXPECTED_TIMEOUT:-5}" || "$2" != "openssl" ]]; then
  exit 9
fi

printf '%s\n' "$1" >> "$MOCK_TIMEOUT_LOG"
shift

if [[ "${MOCK_TIMEOUT_FAILURE:-0}" == 1 ]]; then
  exit 124
fi

exec "$@"
MOCK

cat > "$MOCK_DIR/openssl" <<'MOCK'
#!/usr/bin/env bash

case "$1" in
  s_client)
    shift
    CONNECT=""
    SERVERNAME=""
    VERIFY_HOSTNAME=""
    VERIFY_RETURN_ERROR=0

    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        -connect)
          CONNECT="$2"
          shift 2
          ;;
        -servername)
          SERVERNAME="$2"
          shift 2
          ;;
        -verify_hostname)
          VERIFY_HOSTNAME="$2"
          shift 2
          ;;
        -verify_return_error)
          VERIFY_RETURN_ERROR=1
          shift
          ;;
        *)
          exit 9
          ;;
      esac
    done

    [[ "$VERIFY_RETURN_ERROR" == 1 && "$CONNECT" == "$SERVERNAME:443" && "$VERIFY_HOSTNAME" == "$SERVERNAME" ]] || exit 9

    if [[ "$CONNECT" == "missing.test:443" ]]; then
      exit 1
    fi

    printf '%s\n' "$CONNECT"

    case "$CONNECT" in
      handshake.test:443|untrusted.test:443|wrongname.test:443)
        exit 1
        ;;
    esac
    ;;
  x509)
    read -r DOMAIN || exit 1

    case "$DOMAIN" in
      healthy.test:443|handshake.test:443|untrusted.test:443|wrongname.test:443)
        EXPIRY=$(date -u -d '+120 days' '+%b %d %H:%M:%S %Y GMT')
        ;;
      expiring.test:443)
        EXPIRY=$(date -u -d '+2 days' '+%b %d %H:%M:%S %Y GMT')
        ;;
      invalid.test:443)
        EXPIRY="invalid-date"
        ;;
      *)
        exit 1
        ;;
    esac

    printf 'notAfter=%s\n' "$EXPIRY"
    ;;
  *)
    exit 1
    ;;
esac
MOCK

chmod +x "$MOCK_DIR/openssl" "$MOCK_DIR/timeout"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_TIMEOUT_LOG="$TIMEOUT_CALLS" "$BASH_BIN" "$SCRIPT" "$@"
}

OUTPUT=$(run_check healthy.test) || fail "Healthy certificate should pass"
[[ "$OUTPUT" == "[ OK ] healthy.test certificate is valid for "* ]] || fail "Healthy certificate output incorrect"

OUTPUT=$(TLS_TIMEOUT=10 MOCK_EXPECTED_TIMEOUT=10 run_check healthy.test) || fail "Custom TLS timeout should succeed"
[[ "$OUTPUT" == "[ OK ] healthy.test certificate is valid for "* ]] || fail "Custom timeout output incorrect"
[[ "$(tail -n 1 "$TIMEOUT_CALLS")" == "10" ]] || fail "Configured timeout was not used"

if OUTPUT=$(run_check expiring.test); then
  fail "Expiring certificate should trigger alert"
fi
[[ "$OUTPUT" == "[ALERT] expiring.test certificate expires in "* ]] || fail "Expiration alert missing"

for DOMAIN in missing.test handshake.test untrusted.test wrongname.test; do
  if OUTPUT=$(run_check "$DOMAIN"); then
    fail "$DOMAIN should fail TLS verification or connection"
  fi
  [[ "$OUTPUT" == "[ERROR] TLS connection or certificate verification failed for $DOMAIN" ]] || fail "$DOMAIN failure not reported"
done

if OUTPUT=$(run_check invalid.test); then
  fail "Invalid expiry should fail"
fi
[[ "$OUTPUT" == "[ERROR] Could not parse certificate expiry for invalid.test" ]] || fail "Invalid expiry error incorrect"

if OUTPUT=$(run_check healthy.test untrusted.test); then
  fail "Mixed certificates should fail"
fi
[[ "$OUTPUT" == *"[ OK ] healthy.test"* && "$OUTPUT" == *"[ERROR] TLS connection or certificate verification failed for untrusted.test"* ]] || fail "Mixed results incomplete"

if OUTPUT=$(MOCK_TIMEOUT_FAILURE=1 run_check healthy.test); then
  fail "Timed-out TLS connection should fail"
fi
[[ "$OUTPUT" == "[ERROR] TLS connection or certificate verification failed for healthy.test" ]] || fail "Timeout failure not reported"

: > "$TIMEOUT_CALLS"
for INVALID in '' 0 -1 abc 31 05; do
  if OUTPUT=$(TLS_TIMEOUT="$INVALID" run_check healthy.test 2>&1); then
    fail "Invalid timeout '$INVALID' should fail"
  fi
  [[ "$OUTPUT" == "[ERROR] TLS_TIMEOUT must be an integer between 1 and 30 seconds" ]] || fail "Invalid timeout error incorrect"
done
[[ ! -s "$TIMEOUT_CALLS" ]] || fail "Invalid timeout should not invoke TLS client"

if OUTPUT=$(THRESHOLD=abc run_check healthy.test 2>&1); then
  fail "Invalid threshold should fail"
fi
[[ "$OUTPUT" == "[ERROR] THRESHOLD must be a non-negative integer" ]] || fail "Invalid threshold error incorrect"

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" healthy.test 2>&1); then
  fail "Missing timeout command should fail"
fi
[[ "$OUTPUT" == "[ERROR] Required command not found: timeout" ]] || fail "Missing timeout error incorrect"

echo "[ OK ] ssl-check.sh tests passed"
