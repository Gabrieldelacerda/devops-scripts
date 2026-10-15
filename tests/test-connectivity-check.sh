#!/usr/bin/env bash
# test-connectivity-check.sh — Test ICMP connectivity monitoring

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/connectivity-check.sh"

MOCK_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$MOCK_DIR"' EXIT

# Create a simulated ping command
cat > "$MOCK_DIR/ping" <<'EOF'
#!/usr/bin/env bash

if [[ "$#" -ne 5 || "$1" != "-c" || "$2" != "1" || "$3" != "-W" || "$4" != "2" ]]; then
  exit 2
fi

case "$5" in
  reachable.test) exit 0 ;;
  unreachable.test) exit 1 ;;
  *) exit 2 ;;
esac
EOF

chmod +x "$MOCK_DIR/ping" || exit 1


if ! OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" reachable.test); then
  echo "[FAIL] Reachable host should return success"
  exit 1
fi

if [[ "$OUTPUT" != "[REACHABLE] reachable.test" ]]; then
  echo "[FAIL] Expected reachable host message"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" unreachable.test); then
  echo "[FAIL] Unreachable host should return failure"
  exit 1
fi

if [[ "$OUTPUT" != "[UNREACHABLE] unreachable.test" ]]; then
  echo "[FAIL] Expected unreachable host message"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" bash "$SCRIPT" reachable.test unreachable.test); then
  echo "[FAIL] Mixed results should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[REACHABLE] reachable.test"* ]] ||
   [[ "$OUTPUT" != *"[UNREACHABLE] unreachable.test"* ]]; then
  echo "[FAIL] Expected results for both hosts"
  exit 1
fi

echo "[ OK ] connectivity-check.sh tests passed"
