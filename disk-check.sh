#!/usr/bin/env bash

THRESHOLD=${THRESHOLD:-80}
ALERT=0
COUNT=0

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

if ! DF_OUTPUT=$(df -h --output=pcent,target); then
  echo "[ERROR] Failed to retrieve disk usage"
  exit 1
fi

while read -r USAGE MOUNT; do
  if [[ "$USAGE" == "Use%" ]]; then
    continue
  fi

  if [[ -z "$USAGE" && -z "$MOUNT" ]]; then
    continue
  fi

  if ! [[ "$USAGE" =~ ^(100|[1-9]?[0-9])%$ ]] || [[ -z "$MOUNT" ]]; then
    echo "[ERROR] Invalid disk usage data: $USAGE $MOUNT"
    exit 1
  fi

  PCT=${USAGE%%%}
  COUNT=$((COUNT + 1))

  if [ "$PCT" -ge "$THRESHOLD" ]; then
    echo "[ALERT] $MOUNT is at ${USAGE} usage"
    ALERT=1
  else
    echo "[ OK ]  $MOUNT is at ${USAGE} usage"
  fi
done <<< "$DF_OUTPUT"

if [ "$COUNT" -eq 0 ]; then
  echo "[ERROR] No filesystem usage data found"
  exit 1
fi

exit "$ALERT"
