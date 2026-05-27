#!/bin/bash

echo "Top 5 processes by CPU usage:"
ps aux --sort=-%cpu | awk 'NR<=6 {print $1, $2, $3, $4, $11}'

echo ""
echo "Top 5 processes by memory usage:"
ps aux --sort=-%mem | awk 'NR<=6 {print $1, $2, $3, $4, $11}'
