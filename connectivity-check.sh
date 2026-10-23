#!/usr/bin/env bash

PING_TIMEOUT=${PING_TIMEOUT-2}

if ! [[ "$PING_TIMEOUT" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
  echo "[ERROR] PING_TIMEOUT must be an integer between 1 and 30" >&2
  exit 1
fi

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
  if [[ -z "$HOST" || "$HOST" == -* || "$HOST" =~ [[:space:]] ]]; then
    echo "[INVALID] Invalid host: $HOST"
    FAILED=1
    continue
  fi

  if PING_OUTPUT=$(ping -c 1 -W "$PING_TIMEOUT" "$HOST" 2>&1); then
    echo "[REACHABLE] $HOST"
  else
    STATUS=$?

    if [ "$STATUS" -eq 1 ]; then
      echo "[UNREACHABLE] $HOST"
    else
      echo "[ERROR] Ping failed for $HOST (exit code: $STATUS)"
      if [[ -n "$PING_OUTPUT" ]]; then
        printf '[DETAIL] %s\n' "$PING_OUTPUT"
      fi
    fi

    FAILED=1
  fi
done

exit "$FAILED"
