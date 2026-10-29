#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/network-stats.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
MISSING_AWK_DIR="$TEST_DIR/missing-awk"
IP_CALLS="$TEST_DIR/ip-calls.log"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$MISSING_AWK_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/ip" <<'MOCK'
#!/bin/sh

printf '%s\n' "$*" >> "$MOCK_IP_CALLS"

if [ "$#" -eq 2 ] && [ "$1" = '-br' ] && [ "$2" = 'addr' ]; then
  ACTION=ip
elif [ "$#" -eq 2 ] && [ "$1" = 'route' ] && [ "$2" = 'show' ]; then
  ACTION=route
elif [ "$#" -eq 3 ] && [ "$1" = 'route' ] && [ "$2" = 'get' ]; then
  ACTION=target-route
else
  exit 2
fi

if [ "${MOCK_FAIL_CMD:-}" = "$ACTION" ]; then
  exit 1
fi

if [ "${MOCK_EMPTY_CMD:-}" = "$ACTION" ]; then
  exit 0
fi

case "$ACTION" in
  ip)
    printf '%s\n' 'eth0 UP 192.0.2.10/24'
    ;;
  route)
    printf '%s\n' \
      'default via 192.0.2.1 dev eth0' \
      '192.0.2.0/24 dev eth0 proto kernel'
    ;;
  target-route)
    case "$3" in
      198.51.100.42)
        printf '%s\n' '198.51.100.42 via 192.0.2.1 dev eth0 src 192.0.2.10'
        ;;
      2001:db8::42)
        printf '%s\n' '2001:db8::42 dev eth0 src 2001:db8::10'
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
esac
MOCK

cat > "$MOCK_DIR/awk" <<'MOCK'
#!/bin/sh

[ "$#" -eq 2 ] && [ "$2" = '/proc/net/dev' ] || exit 2

if [ "${MOCK_FAIL_CMD:-}" = "awk" ]; then
  exit 1
fi

if [ "${MOCK_EMPTY_CMD:-}" = "awk" ]; then
  exit 0
fi

printf '%s\n' \
  'eth0 RX: 1200 bytes errors: 0 drops: 0 | TX: 450 bytes errors: 0 drops: 0'
MOCK

cat > "$MOCK_DIR/ss" <<'MOCK'
#!/bin/sh

[ "$#" -eq 1 ] && [ "$1" = '-tuln' ] || exit 2

if [ "${MOCK_FAIL_CMD:-}" = "ss" ]; then
  exit 1
fi

if [ "${MOCK_EMPTY_CMD:-}" = "ss" ]; then
  exit 0
fi

printf '%s\n' \
  'Netid State Local Address:Port' \
  'tcp LISTEN 0.0.0.0:22'
MOCK

chmod +x "$MOCK_DIR/ip" "$MOCK_DIR/awk" "$MOCK_DIR/ss"

run_check() {
  PATH="$MOCK_DIR" MOCK_IP_CALLS="$IP_CALLS" "$BASH_BIN" "$SCRIPT"
}

OUTPUT=$(run_check) ||
  fail "Network report should succeed"

for EXPECTED in \
  'Network interfaces:' \
  'eth0 UP 192.0.2.10/24' \
  'Routing table:' \
  'default via 192.0.2.1 dev eth0' \
  'Network statistics:' \
  'eth0 RX: 1200 bytes' \
  'Listening sockets:' \
  'tcp LISTEN 0.0.0.0:22'; do

  [[ "$OUTPUT" == *"$EXPECTED"* ]] ||
    fail "Expected output not found: $EXPECTED"
done

[[ "$OUTPUT" != *'Route to '* ]] ||
  fail "Route lookup should not run by default"

[[ "$(cat "$IP_CALLS")" == $'-br addr\nroute show' ]] ||
  fail "Default report should not request a destination route"

OUTPUT=$(MOCK_IP_CALLS="$IP_CALLS" PATH="$MOCK_DIR" MOCK_EMPTY_CMD=route "$BASH_BIN" "$SCRIPT") ||
  fail "Empty routing table should not fail the report"

[[ "$OUTPUT" == *'[INFO] No routes reported'* ]] ||
  fail "Empty routing table should be identified"

: > "$IP_CALLS"

OUTPUT=$(ROUTE_TARGET=198.51.100.42 run_check) ||
  fail "Destination route lookup should succeed"

[[ "$OUTPUT" == *'Route to 198.51.100.42:'* ]] ||
  fail "Destination route heading missing"

[[ "$OUTPUT" == *'198.51.100.42 via 192.0.2.1 dev eth0 src 192.0.2.10'* ]] ||
  fail "Selected route details missing"

[[ "$(tail -n 1 "$IP_CALLS")" == 'route get 198.51.100.42' ]] ||
  fail "Destination was not passed to ip route get"

: > "$IP_CALLS"

OUTPUT=$(ROUTE_TARGET=2001:db8::42 run_check) ||
  fail "IPv6 destination route lookup should succeed"

[[ "$OUTPUT" == *'2001:db8::42 dev eth0 src 2001:db8::10'* ]] ||
  fail "IPv6 route details missing"

[[ "$(tail -n 1 "$IP_CALLS")" == 'route get 2001:db8::42' ]] ||
  fail "IPv6 destination was not passed correctly"

for INVALID in '-bad' 'bad host' 'bad/host'; do
  : > "$IP_CALLS"

  if OUTPUT=$(ROUTE_TARGET="$INVALID" run_check); then
    fail "Invalid route target '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == "[ERROR] Invalid ROUTE_TARGET: $INVALID" ]] ||
    fail "Invalid route target error is incorrect"

  [[ ! -s "$IP_CALLS" ]] ||
    fail "Invalid route target reached ip"
done

if OUTPUT=$(ROUTE_TARGET=198.51.100.42 MOCK_FAIL_CMD=target-route run_check); then
  fail "Failed destination route lookup should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Failed to find route to 198.51.100.42'* ]] ||
  fail "Destination route failure was not reported"

if OUTPUT=$(ROUTE_TARGET=198.51.100.42 MOCK_EMPTY_CMD=target-route run_check); then
  fail "Empty destination route lookup should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Route lookup returned no data for 198.51.100.42'* ]] ||
  fail "Empty destination route was not reported"

cp "$MOCK_DIR/ip" "$MOCK_DIR/ss" "$MISSING_AWK_DIR/"

if OUTPUT=$(PATH="$MISSING_AWK_DIR" "$BASH_BIN" "$SCRIPT" 2>&1); then
  fail "Missing awk should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: awk'* ]] ||
  fail "Missing dependency error not found"

for FAILED_CMD in ip route awk ss; do
  case "$FAILED_CMD" in
    ip) EXPECTED_ERROR="Failed to retrieve network interfaces" ;;
    route) EXPECTED_ERROR="Failed to retrieve routing table" ;;
    awk) EXPECTED_ERROR="Failed to retrieve network statistics" ;;
    ss) EXPECTED_ERROR="Failed to retrieve listening sockets" ;;
  esac

  if OUTPUT=$(MOCK_IP_CALLS="$IP_CALLS" PATH="$MOCK_DIR" MOCK_FAIL_CMD="$FAILED_CMD" \
      "$BASH_BIN" "$SCRIPT" 2>&1); then
    fail "$FAILED_CMD failure should return an error"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "Missing error message for $FAILED_CMD"
done

for EMPTY_CMD in ip awk ss; do
  case "$EMPTY_CMD" in
    ip) EXPECTED_ERROR="Network interface output is empty" ;;
    awk) EXPECTED_ERROR="Network statistics output is empty" ;;
    ss) EXPECTED_ERROR="Listening sockets output is empty" ;;
  esac

  if OUTPUT=$(MOCK_IP_CALLS="$IP_CALLS" PATH="$MOCK_DIR" MOCK_EMPTY_CMD="$EMPTY_CMD" \
      "$BASH_BIN" "$SCRIPT" 2>&1); then
    fail "Empty $EMPTY_CMD output should return an error"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "Missing empty output error for $EMPTY_CMD"
done

echo "[ OK ] network-stats.sh tests passed"
