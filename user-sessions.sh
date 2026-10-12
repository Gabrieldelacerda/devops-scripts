#!/usr/bin/env bash
# user-sessions.sh — Show active user sessions on the server

LIMIT=${1:-5}

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
who

echo ""
echo "Logged in users:"
w

echo ""
echo "Last $LIMIT logins:"
if command -v last >/dev/null 2>&1; then
  last -n "$LIMIT"
else
  echo "[WARN] 'last' command is not available"
fi

echo ""
echo "Last $LIMIT failed login attempts:"
if command -v lastb >/dev/null 2>&1; then
  lastb -n "$LIMIT"
else
  echo "[WARN] 'lastb' command is not available"
fi
