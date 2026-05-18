#!/bin/bash
#log-cleanup.sh Delete log files older than X days

LOG_DIR="/var/log"
DAYS=30

echo "Removing log files older than $DAYS days in $LOG_DIR..."
find "$LOG_DIR" -name "*.log" -mtime +$DAYS -delete
echo "Done."
