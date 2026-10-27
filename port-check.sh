#!/usr/bin/env bash

HOST="${1-localhost}"
CONNECT_TIMEOUT="${CONNECT_TIMEOUT:-2}"

if ! [[ "$CONNECT_TIMEOUT" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
  echo "[ERROR] CONNECT_TIMEOUT must be an integer between 1 and 30 seconds"
  exit 1
fi

if [[ -z "$HOST" || "$HOST" == -* || "$HOST" =~ [[:space:]/] ]]; then
  echo "[INVALID] Invalid host: $HOST"
  exit 1
fi

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
  if ! [[ "$PORT" =~ ^[0-9]{1,5}$ ]]; then
    echo "[INVALID] Port must be between 1 and 65535: $PORT"
    FAILED=1
    continue
  fi

  PORT_NUMBER=$((10#$PORT))

  if ((PORT_NUMBER < 1 || PORT_NUMBER > 65535)); then
    echo "[INVALID] Port must be between 1 and 65535: $PORT"
    FAILED=1
    continue
  fi

  if nc "-zw${CONNECT_TIMEOUT}" "$HOST" "$PORT_NUMBER" 2>/dev/null; then
    echo "[OPEN] $HOST:$PORT_NUMBER"
  else
    echo "[UNREACHABLE] $HOST:$PORT_NUMBER"
    FAILED=1
  fi
done

exit "$FAILED"
