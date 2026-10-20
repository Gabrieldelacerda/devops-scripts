#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/disk-check.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

MOCK_DIR="$TEST_DIR/mock-bin"
CALLS="$TEST_DIR/df-calls.log"
mkdir -p "$MOCK_DIR"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$MOCK_DIR/df" <<'MOCK'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "$MOCK_DF_CALLS"

[[ "$#" -eq 2 && "$1" == '-h' && "$2" == '--output=pcent,target' ]] || exit 2

if [[ "${MOCK_DF_FAIL:-0}" == '1' ]]; then
  exit 2
fi

case "${MOCK_DF_CASE:-normal}" in
  normal)
    printf 'Use%% Mounted on\n25%% /test-root\n90%% /test-data\n'
    ;;
  multiple)
    printf 'Use%% Mounted on\n25%% /test-root\n80%% /test-app\n90%% /test-data\n'
    ;;
  boundary)
    printf 'Use%% Mounted on\n0%% /empty\n100%% /full\n'
    ;;
  *)
    exit 2
    ;;
esac
MOCK

chmod +x "$MOCK_DIR/df"

run_check() {
  PATH="$MOCK_DIR:$PATH" MOCK_DF_CALLS="$CALLS" \
    THRESHOLD="$1" MOCK_DF_CASE="${2:-normal}" MOCK_DF_FAIL="${3:-0}" \
    bash "$SCRIPT"
}

OUTPUT=$(run_check 95) || fail "Healthy disks should pass"

[[ "$OUTPUT" == *'[ OK ]  /test-root is at 25% usage'* ]] ||
  fail "Root disk status is incorrect"

[[ "$OUTPUT" == *'[ OK ]  /test-data is at 90% usage'* ]] ||
  fail "Data disk status is incorrect"

if OUTPUT=$(run_check 90); then
  fail "Usage equal to the threshold must trigger an alert"
fi

[[ "$OUTPUT" == *'[ALERT] /test-data is at 90% usage'* ]] ||
  fail "Threshold boundary was not detected"

[[ "$OUTPUT" == *'[ OK ]  /test-root is at 25% usage'* ]] ||
  fail "Healthy filesystem should still be reported"

if OUTPUT=$(run_check 80 multiple); then
  fail "At least one high-usage filesystem must fail the check"
fi

[[ "$OUTPUT" == *'[ALERT] /test-app is at 80% usage'* ]] ||
  fail "Filesystem exactly at threshold was missed"

[[ "$OUTPUT" == *'[ALERT] /test-data is at 90% usage'* ]] ||
  fail "Filesystem above threshold was missed"

[[ "$OUTPUT" == *'[ OK ]  /test-root is at 25% usage'* ]] ||
  fail "Healthy filesystem was missed"

if OUTPUT=$(run_check 100 boundary); then
  fail "A full filesystem must trigger an alert at 100 percent"
fi

[[ "$OUTPUT" == *'[ALERT] /full is at 100% usage'* ]] ||
  fail "Full filesystem alert was missed"

[[ "$OUTPUT" == *'[ OK ]  /empty is at 0% usage'* ]] ||
  fail "Empty filesystem should be healthy at threshold 100"

if OUTPUT=$(run_check 0 boundary); then
  fail "Threshold zero must flag every filesystem"
fi

[[ "$OUTPUT" == *'[ALERT] /empty is at 0% usage'* ]] ||
  fail "Threshold zero behavior is incorrect"

for INVALID in abc -1 101 80.5; do
  : > "$CALLS"

  if OUTPUT=$(run_check "$INVALID"); then
    fail "Invalid threshold '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == '[ERROR] THRESHOLD must be an integer between 0 and 100' ]] ||
    fail "Incorrect error message for '$INVALID'"

  [[ ! -s "$CALLS" ]] ||
    fail "df was called for invalid threshold '$INVALID'"
done

if OUTPUT=$(run_check 80 normal 1); then
  fail "A failing df command must fail the check"
fi

[[ "$OUTPUT" == '[ERROR] Failed to retrieve disk usage' ]] ||
  fail "df failure was not reported"

[[ -s "$CALLS" ]] ||
  fail "df was not executed"

[[ "$(tail -n 1 "$CALLS")" == '-h --output=pcent,target' ]] ||
  fail "Unexpected df arguments"

echo '[ OK ] disk-check.sh tests passed'
