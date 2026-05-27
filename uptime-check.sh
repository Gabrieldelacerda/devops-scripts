#uptime-check.sh — Show server uptime and load average

LOAD=$(uptime | awk -F'load average:' '{print $2}')

echo "Uptime: $(uptime -p)"
echo "Load average: $LOAD"
