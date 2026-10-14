#!/usr/bin/env bash
# test-port-check.sh — Test TCP port monitoring

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/port-check.sh"

MOCK_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$MOCK_DIR"' EXIT

# Create a simulated nc command
cat > "$MOCK_DIR/nc" <<'EOF'
#!/usr/bin/env bash

if [[ "$1" != "-zw2" || "$2" != "example.test" ]]; then
  exit 2
fi

case "$3" in
  22) exit 0 ;;
  81) exit 1 ;;
  *) exit 2 ;;
esac
EOF

chmod +x "$MOCK_DIR/nc" || exit 1


if ! OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" example.test 22); then
  echo "[FAIL] Open port should return success"
  exit 1
fi

if [[ "$OUTPUT" != "[OPEN] example.test:22" ]]; then
  echo "[FAIL] Expected open port message"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" example.test 81); then
  echo "[FAIL] Unreachable port should return failure"
  exit 1
fi

if [[ "$OUTPUT" != "[UNREACHABLE] example.test:81" ]]; then
  echo "[FAIL] Expected unreachable port message"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" example.test 99999); then
  echo "[FAIL] Invalid port should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[INVALID] Port must be between 1 and 65535: 99999"* ]]; then
  echo "[FAIL] Expected invalid port message"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" example.test 22 81); then
  echo "[FAIL] Mixed results should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[OPEN] example.test:22"* ]] ||
   [[ "$OUTPUT" != *"[UNREACHABLE] example.test:81"* ]]; then
  echo "[FAIL] Expected results for both ports"
  exit 1
fi

echo "[ OK ] port-check.sh tests passed"
