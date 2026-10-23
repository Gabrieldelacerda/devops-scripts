#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/network-stats.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
MISSING_AWK_DIR="$TEST_DIR/missing-awk"
BASH_BIN="$(command -v bash)"

mkdir -p "$MOCK_DIR" "$MISSING_AWK_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/ip" <<'MOCK'
#!/bin/sh

if [ "$#" -eq 2 ] && [ "$1" = '-br' ] && [ "$2" = 'addr' ]; then
  ACTION=ip
elif [ "$#" -eq 2 ] && [ "$1" = 'route' ] && [ "$2" = 'show' ]; then
  ACTION=route
else
  exit 2
fi

if [ "${MOCK_FAIL_CMD:-}" = "$ACTION" ]; then
  exit 1
fi

if [ "${MOCK_EMPTY_CMD:-}" = "$ACTION" ]; then
  exit 0
fi

if [ "$ACTION" = 'ip' ]; then
  printf '%s\n' 'eth0 UP 192.0.2.10/24'
else
  printf '%s\n' \
    'default via 192.0.2.1 dev eth0' \
    '192.0.2.0/24 dev eth0 proto kernel'
fi
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

OUTPUT=$(PATH="$MOCK_DIR" "$BASH_BIN" "$SCRIPT") ||
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

OUTPUT=$(PATH="$MOCK_DIR" MOCK_EMPTY_CMD=route "$BASH_BIN" "$SCRIPT") ||
  fail "Empty routing table should not fail the report"

[[ "$OUTPUT" == *'[INFO] No routes reported'* ]] ||
  fail "Empty routing table should be identified"

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

  if OUTPUT=$(PATH="$MOCK_DIR" MOCK_FAIL_CMD="$FAILED_CMD" \
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

  if OUTPUT=$(PATH="$MOCK_DIR" MOCK_EMPTY_CMD="$EMPTY_CMD" \
      "$BASH_BIN" "$SCRIPT" 2>&1); then
    fail "Empty $EMPTY_CMD output should return an error"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "Missing empty output error for $EMPTY_CMD"
done

echo "[ OK ] network-stats.sh tests passed"
