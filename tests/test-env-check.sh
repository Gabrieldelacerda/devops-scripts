#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd) || exit 1
SCRIPT="$ROOT_DIR/env-check.sh"

fail() {
  echo "[FAIL] $1"
  exit 1
}

if ! OUTPUT=$(env TEST_ENV_PRESENT=secret_test_value bash "$SCRIPT" TEST_ENV_PRESENT); then
  fail "Existing variable should return success"
fi

[[ "$OUTPUT" == "[ OK ] TEST_ENV_PRESENT is set" ]] ||
  fail "Existing variable produced unexpected output"

[[ "$OUTPUT" != *"secret_test_value"* ]] ||
  fail "Environment variable value was exposed"

if OUTPUT=$(env -u TEST_ENV_MISSING bash "$SCRIPT" TEST_ENV_MISSING); then
  fail "Missing variable should return failure"
fi

[[ "$OUTPUT" == "[MISSING] TEST_ENV_MISSING is not set" ]] ||
  fail "Missing variable produced unexpected output"

if OUTPUT=$(env TEST_ENV_EMPTY= bash "$SCRIPT" TEST_ENV_EMPTY); then
  fail "Empty variable should return failure"
fi

[[ "$OUTPUT" == "[MISSING] TEST_ENV_EMPTY is not set" ]] ||
  fail "Empty variable produced unexpected output"

for INVALID in "INVALID-NAME" "1INVALID" "HOME[0]" ""; do
  if OUTPUT=$(bash "$SCRIPT" "$INVALID" 2>&1); then
    fail "Invalid variable name should return failure"
  fi

  [[ "$OUTPUT" == "[ERROR] Invalid variable name: $INVALID" ]] ||
    fail "Invalid variable name produced unexpected output"
done

if OUTPUT=$(env -u TEST_ENV_MISSING TEST_ENV_PRESENT=secret_test_value bash "$SCRIPT" TEST_ENV_PRESENT INVALID-NAME TEST_ENV_MISSING 2>&1); then
  fail "Mixed valid and invalid variables should return failure"
fi

[[ "$OUTPUT" == *"[ OK ] TEST_ENV_PRESENT is set"* ]] ||
  fail "Valid variable was not checked"

[[ "$OUTPUT" == *"[ERROR] Invalid variable name: INVALID-NAME"* ]] ||
  fail "Invalid variable was not detected"

[[ "$OUTPUT" == *"[MISSING] TEST_ENV_MISSING is not set"* ]] ||
  fail "Missing variable was not detected"

[[ "$OUTPUT" != *"secret_test_value"* ]] ||
  fail "Environment variable value was exposed"

echo "[ OK ] env-check.sh tests passed"
