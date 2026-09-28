#!/bin/bash

if [ "$#" -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=("nginx" "docker" "ssh")
fi

for SERVICE in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$SERVICE"; then
    echo "$SERVICE is running"
  else
    echo "$SERVICE is NOT running"
  fi
done
