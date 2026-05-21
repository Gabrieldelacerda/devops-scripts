#port-check.sh Check if ports are open on a host

HOST="localhost"
PORTS=(22 80 443 3306)

for PORT in "${PORTS[@]}"; do
  if nc -zw2 "$HOST" "$PORT" 2>/dev/null; then
    echo "Port $PORT is open"
  else
    echo "Port $PORT is closed"
  fi
done
