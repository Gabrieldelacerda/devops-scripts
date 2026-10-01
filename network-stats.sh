#!/bin/bash
for CMD in ip ss awk; do
  if ! command -v "$CMD" >/dev/null 2>&1; then
    echo "[ERROR] Required command not found: $CMD"
    exit 1
  fi
done

echo "Network interfaces:"
ip -br addr

echo ""
echo "Network statistics:"
awk 'NR>2 {print $1, "RX:", $2, "bytes", "TX:", $10, "bytes"}' /proc/net/dev

echo ""
echo "Listening sockets:"
ss -tuln
