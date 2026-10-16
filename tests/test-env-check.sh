#!/usr/bin/env bash
# test-env-check.sh — Test environment variable validation

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/env-check.sh"

# Test 1: Existing variable should pass without exposing its value.
if ! OUTPUT=$(env TEST_ENV_PRESENT=ready bash "$SCRIPT" TEST_ENV_PRESENT); then
  echo "[FAIL] Existing variable should return success"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ] TEST_ENV_PRESENT is set"* ]]; then
  echo "[FAIL] Existing variable produced unexpected output"
  exit 1
fi

if [[ "$OUTPUT" == *"ready"* ]]; then
  echo "[FAIL] Environment variable value was exposed"
  exit 1
fi

# Test 2: Missing variable should fail.
if OUTPUT=$(env -u TEST_ENV_MISSING bash "$SCRIPT" TEST_ENV_MISSING); then
  echo "[FAIL] Missing variable should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[MISSING] TEST_ENV_MISSING is not set"* ]]; then
  echo "[FAIL] Missing variable produced unexpected output"
  exit 1
fi

echo "[ OK ] env-check.sh tests passed"
