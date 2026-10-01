#!/usr/bin/env bash
# uptime-check.sh — Show server uptime and load average

LOAD=$(uptime | awk -F'load average:' '{print $2}')
LOAD_1=$(awk '{print $1}' /proc/loadavg)
CPUS=$(nproc)
THRESHOLD=${LOAD_THRESHOLD:-$CPUS}

echo "Uptime: $(uptime -p)"
echo "Load average: $LOAD"
echo "Logical CPUs: $CPUS"

if ! [[ "$THRESHOLD" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
  echo "[ERROR] LOAD_THRESHOLD must be a non-negative number"
  exit 1
fi

if ! COMPARISON=$(awk -v current_load="$LOAD_1" -v threshold="$THRESHOLD" \
  'BEGIN {print (current_load >= threshold) ? 1 : 0}'); then
  echo "[ERROR] Failed to compare load average"
  exit 1
fi

if [ "$COMPARISON" -eq 1 ]; then
  echo "[ALERT] 1-minute load is $LOAD_1 (threshold: $THRESHOLD)"
  exit 1
else
  echo "[ OK ] 1-minute load is $LOAD_1 (threshold: $THRESHOLD)"
  exit 0
fi
