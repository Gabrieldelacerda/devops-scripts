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
awk 'NR>2 {
  gsub(":", "", $1)
  print $1,
        "RX:", $2, "bytes",
        "errors:", $4,
        "drops:", $5,
        "| TX:", $10, "bytes",
        "errors:", $12,
        "drops:", $13
}' /proc/net/dev

echo ""
echo "Listening sockets:"
ss -tuln
