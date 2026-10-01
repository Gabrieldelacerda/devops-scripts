#!/bin/bash

LIMIT="${1:-5}"

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [positive-number]"
  exit 1
fi

echo "Top $LIMIT processes by CPU usage:"
ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -n "$((LIMIT + 1))"

echo ""
echo "Top $LIMIT processes by memory usage:"
ps -eo user,pid,%cpu,%mem,comm --sort=-%mem | head -n "$((LIMIT + 1))"
