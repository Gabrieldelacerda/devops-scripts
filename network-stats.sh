#!/bin/bash

echo "Network interfaces:"
ip -br addr

echo ""
echo "Network statistics:"
awk 'NR>2 {print $1, "RX:", $2, "bytes", "TX:", $10, "bytes"}' /proc/net/dev

echo ""
echo "Active connections:"
ss -tuln
