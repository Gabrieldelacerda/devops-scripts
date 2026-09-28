#!/usr/bin/env bash

HOST="${1:-localhost}"

if [ "$#" -gt 1 ]; then
  PORTS=("${@:2}")
else
  PORTS=(22 80 443 3306)
fi

for PORT in "${PORTS[@]}"; do
  if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "[INVALID] Port must be between 1 and 65535: $PORT"
    continue
  fi

  if nc -zw2 "$HOST" "$PORT" 2>/dev/null; then
    echo "$HOST:$PORT is open"
  else
    echo "$HOST:$PORT is closed"
  fi
done
