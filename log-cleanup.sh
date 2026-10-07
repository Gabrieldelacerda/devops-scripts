#!/bin/bash
# log-cleanup.sh — Delete log files older than X days

LOG_DIR=${1:-/var/log}
DAYS=${2:-30}

if [ ! -d "$LOG_DIR" ]; then
  echo "[ERROR] Log directory does not exist: $LOG_DIR"
  exit 1
fi

if ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] DAYS must be a non-negative integer"
  exit 1
fi

echo "Removing log files older than $DAYS days in $LOG_DIR..."

if find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" -delete; then
  echo "[ OK ] Log cleanup completed"
else
  echo "[ERROR] Log cleanup failed in $LOG_DIR"
  exit 1
fi
