#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNNER="$TEST_DIR/run-tests.sh"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "$WORK_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

mkdir -p "$WORK_DIR/empty" "$WORK_DIR/passing" "$WORK_DIR/mixed"

for CASE in empty passing mixed; do
  cp "$RUNNER" "$WORK_DIR/$CASE/run-tests.sh"
done

# Test 1: An empty suite must fail with a clear error.
if OUTPUT=$(bash "$WORK_DIR/empty/run-tests.sh" 2>&1); then
  fail "An empty test suite should return a nonzero exit code"
fi

[[ "$OUTPUT" == *"[ERROR] No tests found"* ]] ||
  fail "An empty test suite should report that no tests were found"

# Test 2: Successful tests should return success and correct totals.
cat > "$WORK_DIR/passing/test-first.sh" <<'TEST'
#!/usr/bin/env bash
exit 0
TEST

cat > "$WORK_DIR/passing/test-second.sh" <<'TEST'
#!/usr/bin/env bash
exit 0
TEST

if ! OUTPUT=$(bash "$WORK_DIR/passing/run-tests.sh" 2>&1); then
  fail "A passing test suite should exit successfully"
fi

[[ "$OUTPUT" == *"[PASS] test-first.sh"* ]] ||
  fail "First passing test was not reported"

[[ "$OUTPUT" == *"[PASS] test-second.sh"* ]] ||
  fail "Second passing test was not reported"

[[ "$OUTPUT" == *"Results: 2 passed, 0 failed"* ]] ||
  fail "Passing test totals are incorrect"

# Test 3: A failed test must not prevent later tests from running.
cat > "$WORK_DIR/mixed/test-01-pass.sh" <<'TEST'
#!/usr/bin/env bash
exit 0
TEST

cat > "$WORK_DIR/mixed/test-02-fail.sh" <<'TEST'
#!/usr/bin/env bash
exit 7
TEST

cat > "$WORK_DIR/mixed/test-03-pass.sh" <<'TEST'
#!/usr/bin/env bash
exit 0
TEST

if OUTPUT=$(bash "$WORK_DIR/mixed/run-tests.sh" 2>&1); then
  fail "A suite containing a failed test should return an error"
fi

[[ "$OUTPUT" == *"[PASS] test-01-pass.sh"* ]] ||
  fail "Passing test before failure was not reported"

[[ "$OUTPUT" == *"[FAIL] test-02-fail.sh"* ]] ||
  fail "Failed test was not reported"

[[ "$OUTPUT" == *"[PASS] test-03-pass.sh"* ]] ||
  fail "Tests after a failure should still execute"

[[ "$OUTPUT" == *"Results: 2 passed, 1 failed"* ]] ||
  fail "Mixed test totals are incorrect"

echo "[ OK ] tests/run-tests.sh tests passed"
