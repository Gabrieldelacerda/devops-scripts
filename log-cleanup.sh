#!/bin/bash
#log-cleanup.sh Delete log files older than X days

LOG_DIR=${1:-/var/log}
DAYS=${2:-30}

echo "Removing log files older than $DAYS days in $LOG_DIR..."
if find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" -delete; then
  echo "Done."
else
  echo "[ERROR] Log cleanup failed in $LOG_DIR"
  exit 1
fi
