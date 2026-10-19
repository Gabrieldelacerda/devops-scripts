#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Mock network commands with configurable failures.
cat > "$MOCK_DIR/ip" <<'EOF'
#!/bin/sh
[ "$#" -eq 2 ] && [ "$1" = '-br' ] && [ "$2" = 'addr' ] || exit 2

if [ "${MOCK_FAIL_CMD:-}" = "ip" ]; then
  exit 1
fi

printf '%s\n' 'eth0 UP 192.0.2.10/24'
EOF

cat > "$MOCK_DIR/awk" <<'EOF'
#!/bin/sh
[ "$#" -eq 2 ] && [ "$2" = '/proc/net/dev' ] || exit 2

if [ "${MOCK_FAIL_CMD:-}" = "awk" ]; then
  exit 1
fi

printf '%s\n' \
  'eth0 RX: 1200 bytes errors: 0 drops: 0 | TX: 450 bytes errors: 0 drops: 0'
EOF

cat > "$MOCK_DIR/ss" <<'EOF'
#!/bin/sh
[ "$#" -eq 1 ] && [ "$1" = '-tuln' ] || exit 2

if [ "${MOCK_FAIL_CMD:-}" = "ss" ]; then
  exit 1
fi

printf '%s\n' \
  'Netid State Local Address:Port' \
  'tcp LISTEN 0.0.0.0:22'
EOF

chmod +x "$MOCK_DIR/ip" "$MOCK_DIR/awk" "$MOCK_DIR/ss"

# Test 1: Successful network report.
if ! OUTPUT=$(PATH="$MOCK_DIR" "$BASH_BIN" "$SCRIPT" 2>&1); then
  fail "Network report should succeed"
fi

for EXPECTED in \
  'Network interfaces:' \
  'eth0 UP 192.0.2.10/24' \
  'Network statistics:' \
  'eth0 RX: 1200 bytes' \
  'Listening sockets:' \
  'tcp LISTEN 0.0.0.0:22'; do

  [[ "$OUTPUT" == *"$EXPECTED"* ]] ||
    fail "Expected output not found: $EXPECTED"
done

# Test 2: Missing dependency.
cp "$MOCK_DIR/ip" "$MOCK_DIR/ss" "$MISSING_AWK_DIR/"

if OUTPUT=$(PATH="$MISSING_AWK_DIR" "$BASH_BIN" "$SCRIPT" 2>&1); then
  fail "Missing awk should fail"
fi

[[ "$OUTPUT" == *'[ERROR] Required command not found: awk'* ]] ||
  fail "Missing dependency error not found"

# Test 3: Runtime failures must produce nonzero exit codes.
for FAILED_CMD in ip awk ss; do
  case "$FAILED_CMD" in
    ip)
      EXPECTED_ERROR="Failed to retrieve network interfaces"
      ;;
    awk)
      EXPECTED_ERROR="Failed to retrieve network statistics"
      ;;
    ss)
      EXPECTED_ERROR="Failed to retrieve listening sockets"
      ;;
  esac

  if OUTPUT=$(PATH="$MOCK_DIR" MOCK_FAIL_CMD="$FAILED_CMD" \
      "$BASH_BIN" "$SCRIPT" 2>&1); then
    fail "$FAILED_CMD failure should return an error"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "Missing error message for $FAILED_CMD"
done

echo "[ OK ] network-stats.sh tests passed"
