#!/usr/bin/env bash

for CMD in ip ss awk; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found: $CMD"
    exit 1
  fi
done

echo "Network interfaces:"

if ! IP_OUTPUT=$(ip -br addr); then
  echo "[ERROR] Failed to retrieve network interfaces"
  exit 1
fi

printf '%s\n' "$IP_OUTPUT"

echo ""
echo "Network statistics:"

if ! STATS_OUTPUT=$(awk 'NR>2 {
  gsub(":", "", $1)
  print $1,
        "RX:", $2, "bytes",
        "errors:", $4,
        "drops:", $5,
        "| TX:", $10, "bytes",
        "errors:", $12,
        "drops:", $13
}' /proc/net/dev); then
  echo "[ERROR] Failed to retrieve network statistics"
  exit 1
fi

printf '%s\n' "$STATS_OUTPUT"

echo ""
echo "Listening sockets:"

if ! SOCKET_OUTPUT=$(ss -tuln); then
  echo "[ERROR] Failed to retrieve listening sockets"
  exit 1
fi

printf '%s\n' "$SOCKET_OUTPUT"
