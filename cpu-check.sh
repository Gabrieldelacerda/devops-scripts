#!/usr/bin/env bash

THRESHOLD=${THRESHOLD:-80}
CPU_STAT_FILE=${CPU_STAT_FILE:-/proc/stat}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

read_cpu_counters() {
  local label usr nice sys idle iowait irq softirq steal rest counter

  read -r label usr nice sys idle iowait irq softirq steal rest < "$CPU_STAT_FILE" || return 1
  [[ "$label" == "cpu" ]] || return 1

  for counter in "$usr" "$nice" "$sys" "$idle" "$iowait" "$irq" "$softirq" "$steal"; do
    [[ "$counter" =~ ^[0-9]+$ ]] || return 1
  done

  TOTAL=$((10#$usr + 10#$nice + 10#$sys + 10#$idle + 10#$iowait + 10#$irq + 10#$softirq + 10#$steal))
  IDLE_TOTAL=$((10#$idle + 10#$iowait))
}

if ! read_cpu_counters; then
  echo "[ERROR] Could not read CPU statistics"
  exit 1
fi

TOTAL_BEFORE=$TOTAL
IDLE_BEFORE=$IDLE_TOTAL

if ! sleep 1; then
  echo "[ERROR] CPU sampling failed"
  exit 1
fi

if ! read_cpu_counters; then
  echo "[ERROR] Could not read CPU statistics"
  exit 1
fi

DELTA_TOTAL=$((TOTAL - TOTAL_BEFORE))
DELTA_IDLE=$((IDLE_TOTAL - IDLE_BEFORE))

if [ "$DELTA_TOTAL" -le 0 ] || [ "$DELTA_IDLE" -lt 0 ] || [ "$DELTA_IDLE" -gt "$DELTA_TOTAL" ]; then
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
