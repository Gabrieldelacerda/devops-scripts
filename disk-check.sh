#!/bin/bash
# disk-check.sh — Alert when disk usage exceeds threshold

THRESHOLD=80

df -h --output=pcent,target | tail -n +2 | while read USAGE MOUNT; do
  PCT=${USAGE%%%}
  if [ "$PCT" -ge "$THRESHOLD" ]; then
    echo "[ALERT] $MOUNT is at ${USAGE} usage"
  else
    echo "[ OK ]  $MOUNT is at ${USAGE} usage"
  fi
done