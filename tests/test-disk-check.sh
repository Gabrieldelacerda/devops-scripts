#!/usr/bin/env bash
# test-disk-check.sh — Test disk usage monitoring

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/disk-check.sh"

MOCK_DIR=$(mktemp -d) || exit 1
trap 'rm -rf -- "$MOCK_DIR"' EXIT

# Create a simulated df command
cat > "$MOCK_DIR/df" <<'EOF'
#!/usr/bin/env bash

if [[ "${MOCK_DF_FAIL:-0}" == "1" ]]; then
  exit 2
fi

printf 'Use%% Mounted on\n25%% /test-root\n90%% /test-data\n'
EOF

chmod +x "$MOCK_DIR/df" || exit 1


if ! OUTPUT=$(PATH="$MOCK_DIR:$PATH" THRESHOLD=95 bash "$SCRIPT"); then
  echo "[FAIL] Healthy disk usage should return success"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ]  /test-data is at 90% usage"* ]]; then
  echo "[FAIL] Unexpected output for healthy disks"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" THRESHOLD=80 bash "$SCRIPT"); then
  echo "[FAIL] High disk usage should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ALERT] /test-data is at 90% usage"* ]]; then
  echo "[FAIL] Expected disk usage alert"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" THRESHOLD=abc bash "$SCRIPT"); then
  echo "[FAIL] Invalid threshold should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] THRESHOLD must be an integer between 0 and 100"* ]]; then
  echo "[FAIL] Expected threshold validation error"
  exit 1
fi


if OUTPUT=$(PATH="$MOCK_DIR:$PATH" MOCK_DF_FAIL=1 THRESHOLD=80 bash "$SCRIPT"); then
  echo "[FAIL] df failure should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] Failed to retrieve disk usage"* ]]; then
  echo "[FAIL] Expected disk collection error"
  exit 1
fi

echo "[ OK ] disk-check.sh tests passed"
