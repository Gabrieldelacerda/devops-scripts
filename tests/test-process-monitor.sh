#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT_DIR/process-monitor.sh"

TEST_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEST_DIR"' EXIT

CALLS="$TEST_DIR/ps-calls.log"

fail() {
  echo "[FAIL] $1"
  exit 1
}

cat > "$TEST_DIR/ps" <<'MOCK'
#!/usr/bin/env bash

printf '%s\n' "$*" >> "$MOCK_PS_CALLS"

if [[ "$#" -eq 3 && "$1" == '-eo' && "$2" == 'user,pid,%cpu,%mem,comm' ]]; then
  FILTER=all
  SORT="$3"
elif [[ "$#" -eq 5 && "$1" == '-u' && "$3" == '-o' && "$4" == 'user,pid,%cpu,%mem,comm' ]]; then
  FILTER="$2"
  SORT="$5"
else
  exit 2
fi

case "$SORT" in
  --sort=-%cpu) TYPE=cpu ;;
  --sort=-%mem) TYPE=memory ;;
  *) exit 2 ;;
esac

if [[ "$FILTER" != all && "$FILTER" != worker && "$FILTER" != 1001 ]]; then
  exit 2
fi

if [[ "${MOCK_PS_FAILURE:-}" == "$TYPE" ]]; then
  echo "Simulated process query failure" >&2
  exit 1
fi

if [[ "${MOCK_PS_OUTPUT:-}" == "$TYPE-empty" ]]; then
  exit 0
fi

printf '%s\n' 'USER PID %CPU %MEM COMMAND'

if [[ "${MOCK_PS_OUTPUT:-}" == "$TYPE-header" ]]; then
  exit 0
fi

if [[ "$FILTER" == all ]]; then
  if [[ "$TYPE" == cpu ]]; then
    printf '%s\n' \
      'runner 101 75.0 1.0 cpu_worker' \
      'runner 102 1.0 85.0 memory_worker'
  else
    printf '%s\n' \
      'runner 102 1.0 85.0 memory_worker' \
      'runner 101 75.0 1.0 cpu_worker'
  fi
else
  if [[ "$TYPE" == cpu ]]; then
    printf '%s\n' \
      'worker 301 60.0 2.0 app_cpu' \
      'worker 302 2.0 70.0 app_memory'
  else
    printf '%s\n' \
      'worker 302 2.0 70.0 app_memory' \
      'worker 301 60.0 2.0 app_cpu'
  fi
fi
MOCK

chmod +x "$TEST_DIR/ps"

run_check() {
  PATH="$TEST_DIR:$PATH" MOCK_PS_CALLS="$CALLS" bash "$SCRIPT" "$@"
}

OUTPUT=$(run_check 1) || fail "Valid process limit should succeed"

EXPECTED=$(cat <<'EXPECTED_OUTPUT'
Top 1 processes by CPU usage:
USER PID %CPU %MEM COMMAND
runner 101 75.0 1.0 cpu_worker

Top 1 processes by memory usage:
USER PID %CPU %MEM COMMAND
runner 102 1.0 85.0 memory_worker
EXPECTED_OUTPUT
)

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Process sorting or output limit is incorrect"

[[ "$(cat "$CALLS")" == $'-eo user,pid,%cpu,%mem,comm --sort=-%cpu\n-eo user,pid,%cpu,%mem,comm --sort=-%mem' ]] ||
  fail "Default process queries changed"

OUTPUT=$(run_check 08) ||
  fail "Leading-zero decimal limit should succeed"

[[ "$OUTPUT" == *'Top 8 processes by CPU usage:'* ]] ||
  fail "Leading-zero limit was not interpreted as decimal"

for INVALID in '' 0 -1 abc 1.5 1001; do
  if OUTPUT=$(run_check "$INVALID" 2>&1); then
    fail "Invalid limit '$INVALID' should fail"
  fi

  [[ "$OUTPUT" == Usage:* ]] ||
    fail "Invalid limit '$INVALID' should show usage"
done

if OUTPUT=$(run_check 1 extra 2>&1); then
  fail "Extra arguments should be rejected"
fi

[[ "$OUTPUT" == Usage:* ]] ||
  fail "Extra arguments should show usage"

OUTPUT=$(run_check) ||
  fail "Default process limit should succeed"

[[ "$OUTPUT" == *'Top 5 processes by CPU usage:'* ]] ||
  fail "Default limit should be 5"

: > "$CALLS"

OUTPUT=$(PROCESS_USER=worker run_check 1) ||
  fail "Filtering processes by user should succeed"

EXPECTED=$(cat <<'EXPECTED_OUTPUT'
Top 1 processes by CPU usage for user worker:
USER PID %CPU %MEM COMMAND
worker 301 60.0 2.0 app_cpu

Top 1 processes by memory usage for user worker:
USER PID %CPU %MEM COMMAND
worker 302 2.0 70.0 app_memory
EXPECTED_OUTPUT
)

[[ "$OUTPUT" == "$EXPECTED" ]] ||
  fail "Filtered process report is incorrect"

[[ "$(cat "$CALLS")" == $'-u worker -o user,pid,%cpu,%mem,comm --sort=-%cpu\n-u worker -o user,pid,%cpu,%mem,comm --sort=-%mem' ]] ||
  fail "User filter was not passed correctly to ps"

: > "$CALLS"

OUTPUT=$(PROCESS_USER=1001 run_check 1) ||
  fail "Numeric user IDs should be accepted"

[[ "$OUTPUT" == *'Top 1 processes by CPU usage for user 1001:'* ]] ||
  fail "Numeric user filter is incorrect"

[[ "$(head -n 1 "$CALLS")" == '-u 1001 -o user,pid,%cpu,%mem,comm --sort=-%cpu' ]] ||
  fail "Numeric UID was not passed correctly to ps"

for INVALID_USER in '-root' 'bad user' 'bad/user' 'root;id'; do
  : > "$CALLS"

  if OUTPUT=$(PROCESS_USER="$INVALID_USER" run_check 1 2>&1); then
    fail "Invalid PROCESS_USER '$INVALID_USER' should fail"
  fi

  [[ "$OUTPUT" == "[ERROR] Invalid PROCESS_USER: $INVALID_USER" ]] ||
    fail "Invalid PROCESS_USER error is incorrect"

  [[ ! -s "$CALLS" ]] ||
    fail "Invalid PROCESS_USER must not invoke ps"
done

for FAILURE in cpu memory; do
  if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_PS_CALLS="$CALLS" MOCK_PS_FAILURE="$FAILURE" bash "$SCRIPT" 1 2>&1); then
    fail "A failed $FAILURE query should return an error"
  fi

  if [[ "$FAILURE" == cpu ]]; then
    EXPECTED_ERROR="[ERROR] Failed to retrieve process list for CPU usage"
  else
    EXPECTED_ERROR="[ERROR] Failed to retrieve process list for memory usage"
  fi

  [[ "$OUTPUT" == *"$EXPECTED_ERROR"* ]] ||
    fail "A failed $FAILURE query should explain the error"
done

for TYPE in cpu memory; do
  if [[ "$TYPE" == cpu ]]; then
    LABEL="CPU"
  else
    LABEL="memory"
  fi

  for MODE in empty header; do
    if OUTPUT=$(PATH="$TEST_DIR:$PATH" MOCK_PS_CALLS="$CALLS" MOCK_PS_OUTPUT="$TYPE-$MODE" bash "$SCRIPT" 1 2>&1); then
      fail "$TYPE $MODE output should return an error"
    fi

    [[ "$OUTPUT" == *"[ERROR] No process data returned for $LABEL usage"* ]] ||
      fail "Missing process data should produce an error"
  done
done

if OUTPUT=$(PROCESS_USER=worker MOCK_PS_OUTPUT=cpu-header run_check 1 2>&1); then
  fail "Filtered output without processes should fail"
fi

[[ "$OUTPUT" == *'[ERROR] No process data returned for CPU usage'* ]] ||
  fail "Empty filtered process result was not detected"

echo "[ OK ] process-monitor.sh tests passed"
