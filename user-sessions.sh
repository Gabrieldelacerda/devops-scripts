#!/usr/bin/env bash

if [ "$#" -gt 1 ]; then
  echo "[ERROR] Expected at most one LIMIT argument" >&2
  exit 1
fi

LIMIT=5

if [ "$#" -eq 1 ]; then
  LIMIT=$1
fi

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "[ERROR] LIMIT must be a positive integer"
  exit 1
fi

for CMD in who w; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found: $CMD"
    exit 1
  fi
done

echo "Active sessions:"
if ! who; then
  echo "[ERROR] Failed to retrieve active sessions (who)" >&2
  exit 1
fi

echo ""
echo "Logged in users:"
if ! w; then
  echo "[ERROR] Failed to retrieve logged-in users (w)" >&2
  exit 1
fi

echo ""
echo "Last $LIMIT logins:"
if command -v last >/dev/null 2>&1; then
  if ! last -n "$LIMIT"; then
    echo "[WARN] Failed to retrieve login history (last)" >&2
  fi
else
  echo "[WARN] 'last' command is not available"
fi

echo ""
echo "Last $LIMIT failed login attempts:"
if command -v lastb >/dev/null 2>&1; then
  if ! lastb -n "$LIMIT"; then
    echo "[WARN] Failed to retrieve failed login attempts (lastb)" >&2
  fi
else
  echo "[WARN] 'lastb' command is not available"
fi

exit 0
