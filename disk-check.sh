#!/bin/bash
# disk-check.sh — Alert when disk usage exceeds threshold

THRESHOLD=${THRESHOLD:-80}
ALERT=0

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

if ! DF_OUTPUT=$(df -h --output=pcent,target); then
  echo "[ERROR] Failed to retrieve disk usage"
  exit 1
fi

while read -r USAGE MOUNT; do
  if [ "$USAGE" = "Use%" ]; then
    continue
  fi

  PCT=${USAGE%%%}

  if [ "$PCT" -ge "$THRESHOLD" ]; then
    echo "[ALERT] $MOUNT is at ${USAGE} usage"
    ALERT=1
  else
    echo "[ OK ]  $MOUNT is at ${USAGE} usage"
  fi
done <<< "$DF_OUTPUT"

exit "$ALERT"
