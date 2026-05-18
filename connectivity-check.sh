
#connectivity-check.sh — Check if hosts are reachable

HOSTS=("8.8.8.8" "1.1.1.1" "github.com")

for HOST in "${HOSTS[@]}"; do
  if ping -c 1 -W 2 "$HOST" &>/dev/null; then
    echo "$HOST is reachable"
  else
    echo "$HOST is NOT reachable"
  fi
done
