#!/bin/bash

if [ "$#" -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=("nginx" "docker" "ssh")
fi

for SERVICE in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$SERVICE"; then
    STATUS="running"
  else
    STATUS="NOT running"
  fi

  if systemctl is-enabled --quiet "$SERVICE" 2>/dev/null; then
    BOOT_STATUS="enabled"
  else
    BOOT_STATUS="disabled"
  fi

  echo "$SERVICE is $STATUS (boot: $BOOT_STATUS)"
done
