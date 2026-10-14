#!/usr/bin/env bash
# test-uptime-check.sh — Test load average monitoring

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/uptime-check.sh"


if ! OUTPUT=$(LOAD_THRESHOLD=999999 bash "$SCRIPT"); then
  echo "[FAIL] Healthy load should return success"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ] 1-minute load is "* ]] ||
   [[ "$OUTPUT" != *"(threshold: 999999)"* ]]; then
  echo "[FAIL] Expected healthy load output"
  exit 1
fi


if OUTPUT=$(LOAD_THRESHOLD=0 bash "$SCRIPT"); then
  echo "[FAIL] Threshold zero should trigger an alert"
  exit 1
fi

if [[ "$OUTPUT" != *"[ALERT] 1-minute load is "* ]] ||
   [[ "$OUTPUT" != *"(threshold: 0)"* ]]; then
  echo "[FAIL] Expected load average alert"
  exit 1
fi


if OUTPUT=$(LOAD_THRESHOLD=abc bash "$SCRIPT"); then
  echo "[FAIL] Invalid threshold should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] LOAD_THRESHOLD must be a non-negative number"* ]]; then
  echo "[FAIL] Expected threshold validation error"
  exit 1
fi


if ! OUTPUT=$(LOAD_THRESHOLD=999999.5 bash "$SCRIPT"); then
  echo "[FAIL] Decimal threshold should be accepted"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ] 1-minute load is "* ]] ||
   [[ "$OUTPUT" != *"(threshold: 999999.5)"* ]]; then
  echo "[FAIL] Expected successful decimal threshold check"
  exit 1
fi

echo "[ OK ] uptime-check.sh tests passed"
