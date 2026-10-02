#!/usr/bin/env bash

# connectivity-check.sh — Check if hosts respond to ICMP

if ! command -v ping >/dev/null 2>&1; then
  echo "[ERROR] Required command not found: ping"
  exit 1
fi

if [ "$#" -gt 0 ]; then
  HOSTS=("$@")
else
  HOSTS=("8.8.8.8" "1.1.1.1" "github.com")
fi

FAILED=0

for HOST in "${HOSTS[@]}"; do
  if ping -c 1 -W 2 "$HOST" &>/dev/null; then
    echo "[REACHABLE] $HOST"
  else
    echo "[UNREACHABLE] $HOST"
    FAILED=1
  fi
done

exit "$FAILED"
