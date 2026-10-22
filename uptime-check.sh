#!/usr/bin/env bash

if ! read -r LOAD_1 LOAD_5 LOAD_15 _ < /proc/loadavg; then
  echo "[ERROR] Failed to read load average" >&2
  exit 1
fi

if ! CPUS=$(nproc); then
  echo "[ERROR] Failed to retrieve CPU count" >&2
  exit 1
fi

if ! [[ "$CPUS" =~ ^[1-9][0-9]*$ ]]; then
  echo "[ERROR] Invalid CPU count: $CPUS" >&2
  exit 1
fi

THRESHOLD=${LOAD_THRESHOLD:-$CPUS}

if ! [[ "$THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "[ERROR] LOAD_THRESHOLD must be a non-negative number" >&2
  exit 1
fi

if ! UPTIME=$(uptime -p) || [[ -z "$UPTIME" ]]; then
  echo "[ERROR] Failed to retrieve system uptime" >&2
  exit 1
fi

echo "Uptime: $UPTIME"
echo "Load average: $LOAD_1, $LOAD_5, $LOAD_15"
echo "Logical CPUs: $CPUS"

if ! COMPARISON=$(awk -v current_load="$LOAD_1" -v threshold="$THRESHOLD" \
  'BEGIN {print (current_load >= threshold) ? 1 : 0}'); then
  echo "[ERROR] Failed to compare load average" >&2
  exit 1
fi

if [ "$COMPARISON" -eq 1 ]; then
  echo "[ALERT] 1-minute load is $LOAD_1 (threshold: $THRESHOLD)"
  exit 1
else
  echo "[ OK ] 1-minute load is $LOAD_1 (threshold: $THRESHOLD)"
  exit 0
fi
