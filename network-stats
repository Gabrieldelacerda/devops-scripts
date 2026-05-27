#!/bin/bash

echo "Network interfaces:"
ip -br addr

echo ""
echo "Network statistics:"
cat /proc/net/dev | awk 'NR>2 {print $1, "RX:", $2, "bytes", "TX:", $10, "bytes"}'

echo ""
echo "Active connections:"
ss -tuln
