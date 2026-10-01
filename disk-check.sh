#!/bin/bash
# disk-check.sh — Alert when disk usage exceeds threshold

THRESHOLD=${THRESHOLD:-80}
ALERT=0

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

while read -r USAGE MOUNT; do
  PCT=${USAGE%%%}

  if [ "$PCT" -ge "$THRESHOLD" ]; then
    echo "[ALERT] $MOUNT is at ${USAGE} usage"
    ALERT=1
  else
    echo "[ OK ]  $MOUNT is at ${USAGE} usage"
  fi
done < <(df -h --output=pcent,target | tail -n +2)

exit "$ALERT"
