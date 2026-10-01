#!/usr/bin/env bash
#cpu-check.sh — Alert when CPU usage exceeds threshold

THRESHOLD=${THRESHOLD:-80}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

CPU=$(top -bn1 | awk '/Cpu\(s\)/ {print int(100 - $8)}')

if [ "$CPU" -ge "$THRESHOLD" ]; then
  echo "[ALERT] CPU usage is at ${CPU}%"
  exit 1
else
  echo "[ OK ] CPU usage is at ${CPU}%"
  exit 0
fi
