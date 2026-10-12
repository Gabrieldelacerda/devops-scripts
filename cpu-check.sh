#!/usr/bin/env bash
# cpu-check.sh — Alert when CPU usage exceeds threshold

THRESHOLD=${THRESHOLD:-80}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

read_cpu_counters() {
  local label usr nice sys idle iowait irq softirq steal rest

  read -r label usr nice sys idle iowait irq softirq steal rest < /proc/stat || return 1
  [[ "$label" == "cpu" ]] || return 1

  TOTAL=$((usr + nice + sys + idle + iowait + irq + softirq + steal))
  IDLE_TOTAL=$((idle + iowait))
}

if ! read_cpu_counters; then
  echo "[ERROR] Could not read CPU statistics"
  exit 1
fi

TOTAL_BEFORE=$TOTAL
IDLE_BEFORE=$IDLE_TOTAL

sleep 1

if ! read_cpu_counters; then
  echo "[ERROR] Could not read CPU statistics"
  exit 1
fi

DELTA_TOTAL=$((TOTAL - TOTAL_BEFORE))
DELTA_IDLE=$((IDLE_TOTAL - IDLE_BEFORE))

if [ "$DELTA_TOTAL" -le 0 ]; then
  echo "[ERROR] Invalid CPU statistics"
  exit 1
fi

CPU=$((100 * (DELTA_TOTAL - DELTA_IDLE) / DELTA_TOTAL))

if [ "$CPU" -ge "$THRESHOLD" ]; then
  echo "[ALERT] CPU usage is at ${CPU}%"
  exit 1
else
  echo "[ OK ] CPU usage is at ${CPU}%"
  exit 0
fi
