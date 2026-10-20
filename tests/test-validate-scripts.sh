#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="$ROOT_DIR/validate-scripts.sh"
BASH_BIN="$(command -v bash)"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf -- "$WORK_DIR"' EXIT

fail() {
  echo "[FAIL] $1"
  exit 1
}

mkdir -p \
  "$WORK_DIR/mock-bin" \
  "$WORK_DIR/no-shellcheck" \
  "$WORK_DIR/passing" \
  "$WORK_DIR/syntax-error" \
  "$WORK_DIR/lint-error"

# Mock ShellCheck to simulate successful and failed checks.
cat > "$WORK_DIR/mock-bin/shellcheck" <<'MOCK'
#!/usr/bin/env bash

if [[ "$1" == *lint-fail.sh ]]; then
  exit 1
fi

exit 0
MOCK

chmod +x "$WORK_DIR/mock-bin/shellcheck"

# Test 1: Detect missing ShellCheck.
if OUTPUT=$(PATH="$WORK_DIR/no-shellcheck" "$BASH_BIN" "$VALIDATOR" 2>&1); then
  fail "Validation should fail when ShellCheck is unavailable"
fi

[[ "$OUTPUT" == *"[ERROR] ShellCheck is required"* ]] ||
  fail "Missing ShellCheck message was not displayed"

# Test 2: Accept valid Bash scripts.
cp "$VALIDATOR" "$WORK_DIR/passing/validate-scripts.sh"

printf '#!/usr/bin/env bash\necho ok\n' \
  > "$WORK_DIR/passing/working.sh"

if ! OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
    "$BASH_BIN" "$WORK_DIR/passing/validate-scripts.sh" 2>&1); then
  fail "Valid scripts should pass validation"
fi

[[ "$OUTPUT" == *"[ OK ] All 2 scripts passed validation"* ]] ||
  fail "Success count is incorrect"

# Test 3: Reject invalid Bash syntax.
cp "$VALIDATOR" "$WORK_DIR/syntax-error/validate-scripts.sh"

printf '#!/usr/bin/env bash\nif then\n' \
  > "$WORK_DIR/syntax-error/broken.sh"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
    "$BASH_BIN" "$WORK_DIR/syntax-error/validate-scripts.sh" 2>&1); then
  fail "Invalid Bash syntax should fail validation"
fi

[[ "$OUTPUT" == *"[ERROR] Syntax check failed:"* ]] ||
  fail "Syntax error was not reported"

[[ "$OUTPUT" == *"Validation failed: 1 of 2 scripts failed"* ]] ||
  fail "Syntax failure count is incorrect"

# Test 4: Detect ShellCheck failures.
cp "$VALIDATOR" "$WORK_DIR/lint-error/validate-scripts.sh"

printf '#!/usr/bin/env bash\necho ok\n' \
  > "$WORK_DIR/lint-error/lint-fail.sh"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
    "$BASH_BIN" "$WORK_DIR/lint-error/validate-scripts.sh" 2>&1); then
  fail "ShellCheck failures should fail validation"
fi

[[ "$OUTPUT" == *"[ERROR] ShellCheck failed:"* ]] ||
  fail "ShellCheck failure was not reported"

[[ "$OUTPUT" == *"Validation failed: 1 of 2 scripts failed"* ]] ||
  fail "ShellCheck failure count is incorrect"

echo "[ OK ] validate-scripts.sh tests passed"
