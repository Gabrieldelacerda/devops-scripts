#cpu-check.sh — Alert when CPU usage exceeds threshold

THRESHOLD=80

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)

if [ "$CPU" -ge "$THRESHOLD" ]; then
  echo "[ALERT] CPU usage is at ${CPU}%"
else
  echo "CPU usage is at ${CPU}%"
fi
