#!/usr/bin/env bash
# run-tests.sh — Run automated Bash tests

TEST_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 1

shopt -s nullglob
TESTS=("$TEST_DIR"/test-*.sh)
shopt -u nullglob

if [ "${#TESTS[@]}" -eq 0 ]; then
  echo "[ERROR] No tests found"
  exit 1
fi

PASSED=0
FAILED=0

for TEST in "${TESTS[@]}"; do
  NAME=${TEST##*/}

  echo "Running $NAME..."

  if bash "$TEST"; then
    echo "[PASS] $NAME"
    PASSED=$((PASSED + 1))
  else
    echo "[FAIL] $NAME"
    FAILED=$((FAILED + 1))
  fi
done

echo ""
echo "Results: $PASSED passed, $FAILED failed"

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi

exit 0
