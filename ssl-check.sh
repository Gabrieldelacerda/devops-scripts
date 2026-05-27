#!/bin/bash

DOMAINS=("google.com" "github.com")
THRESHOLD=30

for DOMAIN in "${DOMAINS[@]}"; do
  EXPIRY=$(echo | openssl s_client -connect "$DOMAIN:443" 2>/dev/null | openssl x509 -noout -enddate | cut -d'=' -f2)
  DAYS=$(( ( $(date -d "$EXPIRY" +%s) - $(date +%s) ) / 86400 ))

  if [ "$DAYS" -le "$THRESHOLD" ]; then
    echo "[ALERT] $DOMAIN certificate expires in $DAYS days"
  else
    echo "$DOMAIN certificate is valid for $DAYS days"
  fi
done
