#!/usr/bin/env bash
#user-sessions.sh — Show active user sessions on the server

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
echo "Last 5 logins:"
if command -v last >/dev/null 2>&1; then
  last -n 5
else
  echo "[WARN] 'last' command is not available"
fi

echo ""
echo "Failed login attempts:"
if command -v lastb >/dev/null 2>&1; then
  lastb -n 5
else
  echo "[WARN] 'lastb' command is not available"
fi
