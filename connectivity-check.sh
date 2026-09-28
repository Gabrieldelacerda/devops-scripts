#!/usr/bin/env bash

# connectivity-check.sh — Check if hosts are reachable

if [ "$#" -gt 0 ]; then
  HOSTS=("$@")
else
  HOSTS=("8.8.8.8" "1.1.1.1" "github.com")
fi

for HOST in "${HOSTS[@]}"; do
  if ping -c 1 -W 2 "$HOST" &>/dev/null; then
    echo "$HOST is reachable"
  else
    echo "$HOST is NOT reachable"
  fi
done
