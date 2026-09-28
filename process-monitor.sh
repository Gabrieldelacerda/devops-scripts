#!/bin/bash

LIMIT="${1:-5}"

if ! [[ "$LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  echo "Usage: $0 [positive-number]"
  exit 1
fi

echo "Top $LIMIT processes by CPU usage:"
ps aux --sort=-%cpu | awk -v limit="$LIMIT" 'NR==1 || (NR>1 && NR<=limit+1) {print $1, $2, $3, $4, $11}'

echo ""
echo "Top $LIMIT processes by memory usage:"
ps aux --sort=-%mem | awk -v limit="$LIMIT" 'NR==1 || (NR>1 && NR<=limit+1) {print $1, $2, $3, $4, $11}'
