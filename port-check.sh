#!/usr/bin/env bash

HOST="${1:-localhost}"

if ! command -v nc >/dev/null 2>&1; then
  echo "[ERROR] Required command not found: nc"
  exit 1
fi

if [ "$#" -gt 1 ]; then
  PORTS=("${@:2}")
else
  PORTS=(22 80 443 3306)
fi

FAILED=0

for PORT in "${PORTS[@]}"; do
  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "[INVALID] Port must be between 1 and 65535: $PORT"
    FAILED=1
    continue
  fi

  if nc -zw2 "$HOST" "$PORT" 2>/dev/null; then
    echo "[OPEN] $HOST:$PORT"
  else
    echo "[UNREACHABLE] $HOST:$PORT"
    FAILED=1
  fi
done

exit "$FAILED"
