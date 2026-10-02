#!/bin/bash

if [ "$#" -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=("nginx" "docker" "ssh")
fi

FAILED=0

for SERVICE in "${SERVICES[@]}"; do
  LOAD_STATE=$(systemctl show "$SERVICE" -p LoadState --value 2>/dev/null)

  if [ "$LOAD_STATE" = "not-found" ] || [ -z "$LOAD_STATE" ]; then
    echo "[ERROR] $SERVICE was not found"
    FAILED=1
    continue
  fi

  if systemctl is-active --quiet "$SERVICE"; then
    STATUS="running"
  else
    STATUS="NOT running"
    FAILED=1
  fi

  SOCKET="${SERVICE%.service}.socket"

  if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
    BOOT_STATUS="enabled"
  elif systemctl is-enabled --quiet "$SOCKET" 2>/dev/null; then
    BOOT_STATUS="socket-activated"
  else
    BOOT_STATUS="disabled"
  fi

  echo "$SERVICE is $STATUS (boot: $BOOT_STATUS)"
done

exit "$FAILED"
