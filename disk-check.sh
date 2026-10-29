#!/usr/bin/env bash

THRESHOLD=${THRESHOLD:-80}
CHECK_INODES=${CHECK_INODES:-0}
ALERT=0
COUNT=0

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]] || [ "$THRESHOLD" -gt 100 ]; then
  echo "[ERROR] THRESHOLD must be an integer between 0 and 100"
  exit 1
fi

if [[ "$CHECK_INODES" != 0 && "$CHECK_INODES" != 1 ]]; then
  echo "[ERROR] CHECK_INODES must be 0 or 1"
  exit 1
fi

if [[ "$CHECK_INODES" == 1 ]]; then
  DF_ARGS=("--output=ipcent,target")
  METRIC="inode"
else
  DF_ARGS=(-h "--output=pcent,target")
  METRIC="disk"
fi

if ! DF_OUTPUT=$(df "${DF_ARGS[@]}"); then
  echo "[ERROR] Failed to retrieve $METRIC usage"
  exit 1
fi

while read -r USAGE MOUNT; do
  if [[ "$USAGE" == "Use%" || "$USAGE" == "IUse%" ]]; then
    continue
  fi

  if [[ -z "$USAGE" && -z "$MOUNT" ]]; then
    continue
  fi

  if [[ "$CHECK_INODES" == 1 && "$USAGE" == "-" && -n "$MOUNT" ]]; then
    echo "[SKIP] $MOUNT inode usage unavailable"
    continue
  fi

  if ! [[ "$USAGE" =~ ^(100|[1-9]?[0-9])%$ ]] || [[ -z "$MOUNT" ]]; then
    echo "[ERROR] Invalid $METRIC usage data: $USAGE $MOUNT"
    exit 1
  fi

  PCT=${USAGE%%%}
  COUNT=$((COUNT + 1))

  if [[ "$CHECK_INODES" == 1 ]]; then
    DESCRIPTION="$MOUNT inode usage is at $USAGE"
  else
    DESCRIPTION="$MOUNT is at $USAGE usage"
  fi

  if [ "$PCT" -ge "$THRESHOLD" ]; then
    echo "[ALERT] $DESCRIPTION"
    ALERT=1
  else
    echo "[ OK ]  $DESCRIPTION"
  fi
done <<< "$DF_OUTPUT"

if [ "$COUNT" -eq 0 ]; then
  if [[ "$CHECK_INODES" == 1 ]]; then
    echo "[ERROR] No filesystem inode usage data found"
  else
    echo "[ERROR] No filesystem usage data found"
  fi
  exit 1
fi

exit "$ALERT"
