#!/bin/bash

SERVICES=("nginx" "docker" "ssh")

for SERVICE in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$SERVICE"; then
    echo "$SERVICE is running"
  else
    echo "$SERVICE is NOT running"
  fi
done
