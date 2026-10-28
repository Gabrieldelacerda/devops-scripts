#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/service-health.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
EMPTY_DIR="$TEST_DIR/empty-bin"
CALLS="$TEST_DIR/systemctl-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$EMPTY_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/systemctl" <<'MOCK'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "$MOCK_SYSTEMCTL_LOG"

case "$1" in
  show)
    case "$2" in
      active|active@worker.service|inactive|socket|static|masked|enabled-runtime)
        echo "loaded"
        ;;
      missing)
        echo "not-found"
        ;;
      unavailable)
        exit 1
        ;;
      *)
        exit 2
        ;;
    esac
    ;;
  is-active)
    case "$3" in
      active|active@worker.service|socket|static|enabled-runtime) exit 0 ;;
      *) exit 3 ;;
    esac
    ;;
  is-enabled)
    if [[ "$2" == "--quiet" ]]; then
      [[ "$3" == "socket.socket" ]]
      exit
    fi

    case "$2" in
      active|active@worker.service)
        echo "enabled"
        ;;
      enabled-runtime)
        echo "enabled-runtime"
        ;;
      static)
        echo "static"
        ;;
      masked)
        echo "masked"
        exit 1
        ;;
      inactive|socket)
        echo "disabled"
        exit 1
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 2
    ;;
esac
MOCK

chmod +x "$MOCK_DIR/systemctl"

run_check() {
  MOCK_SYSTEMCTL_LOG="$CALLS" PATH="$MOCK_DIR:$PATH" "$BASH_BIN" "$SCRIPT" "$@"
}

check_service() {
  local service="$1"
  local expected_status="$2"
  local expected_output="$3"
  local output status

  if output=$(run_check "$service"); then
    status=0
  else
    status=$?
  fi

  if [[ "$status" -ne "$expected_status" || "$output" != "$expected_output" ]]; then
    fail "Unexpected result for $service: $output (exit code: $status)"
  fi
}

check_service active 0 "active is running (boot: enabled)"
check_service inactive 1 "inactive is NOT running (boot: disabled)"
check_service missing 1 "[ERROR] missing was not found"
check_service socket 0 "socket is running (boot: socket-activated)"
check_service unavailable 1 "[ERROR] Could not inspect unavailable"
check_service active@worker.service 0 "active@worker.service is running (boot: enabled)"
check_service static 0 "static is running (boot: static)"
check_service masked 1 "masked is NOT running (boot: masked)"
check_service enabled-runtime 0 "enabled-runtime is running (boot: enabled)"

for SERVICE in '' '-invalid' 'bad service' 'bad/service' 'bad;name'; do
  : > "$CALLS"

  if OUTPUT=$(run_check "$SERVICE"); then
    fail "Invalid service '$SERVICE' should fail"
  fi

  [[ "$OUTPUT" == "[INVALID] Invalid service name: $SERVICE" ]] ||
    fail "Incorrect validation message for '$SERVICE'"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid service '$SERVICE' reached systemctl"
done

: > "$CALLS"

if OUTPUT=$(run_check active 'bad service' inactive); then
  fail "Mixed service results should return failure"
fi

EXPECTED=$'active is running (boot: enabled)\n[INVALID] Invalid service name: bad service\ninactive is NOT running (boot: disabled)'

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Mixed service results are incorrect"

if grep -Fq 'bad service' "$CALLS"; then
  fail "Invalid service was passed to systemctl"
fi

if OUTPUT=$(PATH="$EMPTY_DIR" "$BASH_BIN" "$SCRIPT" active 2>&1); then
  fail "Missing systemctl should return failure"
fi

[[ "$OUTPUT" == *"[ERROR] Required command not found: systemctl"* ]] ||
  fail "Missing systemctl error message not found"

echo "[ OK ] service-health.sh tests passed"
