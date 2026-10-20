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

cat > "$WORK_DIR/mock-bin/shellcheck" <<'MOCK'
#!/usr/bin/env bash

if [[ "$1" == *lint-fail.sh ]]; then
  exit 1
fi

exit 0
MOCK

chmod +x "$WORK_DIR/mock-bin/shellcheck"

if OUTPUT=$(PATH="$WORK_DIR/no-shellcheck" "$BASH_BIN" "$VALIDATOR" 2>&1); then
  fail "Validation should fail when ShellCheck is unavailable"
fi

[[ "$OUTPUT" == *"[ERROR] ShellCheck is required"* ]] ||
  fail "Missing ShellCheck message was not displayed"

cp "$VALIDATOR" "$WORK_DIR/passing/validate-scripts.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$WORK_DIR/passing/working.sh"

if ! OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/passing/validate-scripts.sh" 2>&1); then
  fail "Valid scripts should pass validation"
fi

[[ "$OUTPUT" == *"[ OK ] All 2 scripts passed validation"* ]] ||
  fail "Success count is incorrect"

cp "$VALIDATOR" "$WORK_DIR/syntax-error/validate-scripts.sh"
printf '#!/usr/bin/env bash\nif then\n' > "$WORK_DIR/syntax-error/broken.sh"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/syntax-error/validate-scripts.sh" 2>&1); then
  fail "Invalid Bash syntax should fail validation"
fi

[[ "$OUTPUT" == *"[ERROR] Syntax check failed:"* ]] ||
  fail "Syntax error was not reported"

[[ "$OUTPUT" == *"Validation failed: 1 of 2 scripts failed"* ]] ||
  fail "Syntax failure count is incorrect"

cp "$VALIDATOR" "$WORK_DIR/lint-error/validate-scripts.sh"
printf '#!/usr/bin/env bash\necho ok\n' > "$WORK_DIR/lint-error/lint-fail.sh"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/lint-error/validate-scripts.sh" 2>&1); then
  fail "ShellCheck failures should fail validation"
fi

[[ "$OUTPUT" == *"[ERROR] ShellCheck failed:"* ]] ||
  fail "ShellCheck failure was not reported"

[[ "$OUTPUT" == *"Validation failed: 1 of 2 scripts failed"* ]] ||
  fail "ShellCheck failure count is incorrect"

if ! OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/syntax-error/validate-scripts.sh" \
  "$WORK_DIR/syntax-error/validate-scripts.sh" 2>&1); then
  fail "Targeted validation should ignore unrelated broken files"
fi

[[ "$OUTPUT" == *"[ OK ] All 1 scripts passed validation"* ]] ||
  fail "Targeted validation should report one checked script"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/passing/validate-scripts.sh" \
  "$WORK_DIR/passing/missing.sh" 2>&1); then
  fail "Missing script path should return an error"
fi

[[ "$OUTPUT" == *"[ERROR] Script not found:"* ]] ||
  fail "Missing script path was not reported"

printf 'not a shell script\n' > "$WORK_DIR/passing/notes.txt"

if OUTPUT=$(PATH="$WORK_DIR/mock-bin:$PATH" \
  "$BASH_BIN" "$WORK_DIR/passing/validate-scripts.sh" \
  "$WORK_DIR/passing/notes.txt" 2>&1); then
  fail "Non-shell files should be rejected"
fi

[[ "$OUTPUT" == *"[ERROR] Expected a .sh file:"* ]] ||
  fail "Invalid file extension was not reported"

echo "[ OK ] validate-scripts.sh tests passed"
