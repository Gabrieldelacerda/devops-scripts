#!/usr/bin/env bash
# Remove old log files, with an optional dry-run mode.

LOG_DIR=${1:-/var/log}
DAYS=${2:-30}
MODE=${3:-}

if (( $# > 3 )) || [[ -n "$MODE" && "$MODE" != "--dry-run" ]]; then
  echo "Usage: $0 [log_directory] [days] [--dry-run]"
  exit 1
fi

if [[ ! -d "$LOG_DIR" ]]; then
  echo "[ERROR] Log directory does not exist: $LOG_DIR"
  exit 1
fi

if [[ ! "$DAYS" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] DAYS must be a non-negative integer"
  exit 1
fi

if [[ "$MODE" == "--dry-run" ]]; then
  echo "Dry run: listing log files older than $DAYS days in $LOG_DIR..."

  if ! find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" -print; then
    echo "[ERROR] Failed to inspect log files in $LOG_DIR"
    exit 1
  fi

  echo "[ OK ] Dry run completed; no files deleted"
  exit 0
fi

echo "Removing log files older than $DAYS days in $LOG_DIR..."

if ! find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" -delete; then
  echo "[ERROR] Log cleanup failed in $LOG_DIR"
  exit 1
fi

echo "[ OK ] Log cleanup completed"
