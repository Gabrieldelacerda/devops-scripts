#!/usr/bin/env bash
# test-cpu-check.sh — Test CPU monitoring and alerts

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/cpu-check.sh"

# Test 1: CPU measurement with threshold 100
if OUTPUT=$(THRESHOLD=100 bash "$SCRIPT"); then
  STATUS=0
else
  STATUS=$?
fi

if [[ ! "$OUTPUT" =~ CPU\ usage\ is\ at\ ([0-9]+)%$ ]]; then
  echo "[FAIL] CPU measurement produced unexpected output"
  exit 1
fi

CPU=${BASH_REMATCH[1]}

if [ "$CPU" -gt 100 ]; then
  echo "[FAIL] CPU usage cannot exceed 100%"
  exit 1
fi

if [ "$CPU" -eq 100 ]; then
  if [ "$STATUS" -ne 1 ] || [ "$OUTPUT" != "[ALERT] CPU usage is at 100%" ]; then
    echo "[FAIL] Incorrect result at 100% CPU usage"
    exit 1
  fi
else
  if [ "$STATUS" -ne 0 ] || [ "$OUTPUT" != "[ OK ] CPU usage is at ${CPU}%" ]; then
    echo "[FAIL] Healthy CPU usage should return success"
    exit 1
  fi
fi

# Test 2: Threshold zero should trigger an alert
if OUTPUT=$(THRESHOLD=0 bash "$SCRIPT"); then
  echo "[FAIL] Threshold zero should trigger an alert"
  exit 1
fi

if [[ "$OUTPUT" != "[ALERT] CPU usage is at "* ]]; then
  echo "[FAIL] Expected CPU alert"
  exit 1
fi

# Test 3: Invalid threshold
if OUTPUT=$(THRESHOLD=abc bash "$SCRIPT"); then
  echo "[FAIL] Invalid threshold should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] THRESHOLD must be an integer between 0 and 100"* ]]; then
  echo "[FAIL] Expected threshold validation error"
  exit 1
fi

# Test 4: Threshold above 100
if OUTPUT=$(THRESHOLD=101 bash "$SCRIPT"); then
  echo "[FAIL] Threshold above 100 should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[ERROR] THRESHOLD must be an integer between 0 and 100"* ]]; then
  echo "[FAIL] Expected out-of-range threshold error"
  exit 1
fi

echo "[ OK ] cpu-check.sh tests passed"
