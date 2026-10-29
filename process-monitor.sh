#!/usr/bin/env bash

if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [positive-number]" >&2
  exit 1
fi

LIMIT="${1-5}"
PROCESS_USER="${PROCESS_USER-}"

if ! [[ "$LIMIT" =~ ^0*([1-9][0-9]{0,2}|1000)$ ]]; then
  echo "Usage: $0 [positive-number]" >&2
  exit 1
fi

if [[ -n "$PROCESS_USER" ]] && ! [[ "$PROCESS_USER" =~ ^([a-zA-Z_][a-zA-Z0-9_.-]*\$?|[0-9]+)$ ]]; then
  echo "[ERROR] Invalid PROCESS_USER: $PROCESS_USER" >&2
  exit 1
fi

COUNT=$((10#$LIMIT))

show_top_processes() {
  local LABEL="$1"
  local SORT="$2"
  local PROCESSES
  local SCOPE=""
  local -a PS_ARGS

  if [[ -n "$PROCESS_USER" ]]; then
    PS_ARGS=(-u "$PROCESS_USER" -o "user,pid,%cpu,%mem,comm" "--sort=$SORT")
    SCOPE=" for user $PROCESS_USER"
  else
    PS_ARGS=(-eo "user,pid,%cpu,%mem,comm" "--sort=$SORT")
  fi

  if ! PROCESSES=$(ps "${PS_ARGS[@]}"); then
    echo "[ERROR] Failed to retrieve process list for $LABEL usage" >&2
    return 1
  fi

  if [[ -z "$PROCESSES" || "$PROCESSES" != *$'\n'* ]]; then
    echo "[ERROR] No process data returned for $LABEL usage" >&2
    return 1
  fi

  echo "Top $COUNT processes by $LABEL usage${SCOPE}:"
  head -n "$((COUNT + 1))" <<< "$PROCESSES"
}

show_top_processes "CPU" "-%cpu" || exit 1

echo ""

show_top_processes "memory" "-%mem" || exit 1
