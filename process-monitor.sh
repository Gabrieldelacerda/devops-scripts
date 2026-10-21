#!/bin/bash

LIMIT="${1:-5}"

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [positive-number]"
  exit 1
fi

show_top_processes() {
  local LABEL="$1"
  local SORT="$2"
  local PROCESSES

  if ! PROCESSES=$(ps -eo user,pid,%cpu,%mem,comm "--sort=$SORT"); then
    echo "[ERROR] Failed to retrieve process list for $LABEL usage" >&2
    return 1
  fi

  echo "Top $LIMIT processes by $LABEL usage:"
  printf '%s\n' "$PROCESSES" | head -n "$((LIMIT + 1))"
}

show_top_processes "CPU" "-%cpu" || exit 1

echo ""

show_top_processes "memory" "-%mem" || exit 1
