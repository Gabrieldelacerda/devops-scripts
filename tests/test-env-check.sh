
#!/usr/bin/env bash
# Test environment variable validation without exposing values.

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/env-check.sh"

# An existing variable must pass without printing its value.
if ! OUTPUT=$(env TEST_ENV_PRESENT=secret_test_value bash "$SCRIPT" TEST_ENV_PRESENT); then
  echo "[FAIL] Existing variable should return success"
  exit 1
fi

if [[ "$OUTPUT" != *"[ OK ] TEST_ENV_PRESENT is set"* ]]; then
  echo "[FAIL] Existing variable produced unexpected output"
  exit 1
fi

if [[ "$OUTPUT" == *"secret_test_value"* ]]; then
  echo "[FAIL] Environment variable value was exposed"
  exit 1
fi

# A missing variable must return an error.
if OUTPUT=$(env -u TEST_ENV_MISSING bash "$SCRIPT" TEST_ENV_MISSING); then
  echo "[FAIL] Missing variable should return failure"
  exit 1
fi

if [[ "$OUTPUT" != *"[MISSING] TEST_ENV_MISSING is not set"* ]]; then
  echo "[FAIL] Missing variable produced unexpected output"
  exit 1
fi

echo "[ OK ] env-check.sh tests passed"
