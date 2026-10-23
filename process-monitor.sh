#!/usr/bin/env bash

if [ "$#" -gt 1 ]; then
  echo "Usage: $0 [positive-number]" >&2
  exit 1
fi

LIMIT="${1-5}"

if ! [[ "$LIMIT" =~ ^0*([1-9][0-9]{0,2}|1000)$ ]]; then
  echo "Usage: $0 [positive-number]" >&2
  exit 1
fi

COUNT=$((10#$LIMIT))

show_top_processes() {
  local LABEL="$1"
  local SORT="$2"
  local PROCESSES

  if ! PROCESSES=$(ps -eo user,pid,%cpu,%mem,comm "--sort=$SORT"); then
    echo "[ERROR] Failed to retrieve process list for $LABEL usage" >&2
    return 1
  fi

  if [[ -z "$PROCESSES" || "$PROCESSES" != *$'\n'* ]]; then
    echo "[ERROR] No process data returned for $LABEL usage" >&2
    return 1
  fi

  echo "Top $COUNT processes by $LABEL usage:"
  head -n "$((COUNT + 1))" <<< "$PROCESSES"
}

show_top_processes "CPU" "-%cpu" || exit 1

echo ""

show_top_processes "memory" "-%mem" || exit 1
