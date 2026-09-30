#!/bin/bash

if [ "$#" -gt 0 ]; then
  DOMAINS=("$@")
else
  DOMAINS=("google.com" "github.com")
fi

THRESHOLD=${THRESHOLD:-30}

for DOMAIN in "${DOMAINS[@]}"; do
  CERT_INFO=$(echo | openssl s_client \
    -connect "$DOMAIN:443" \
    -servername "$DOMAIN" \
    2>/dev/null | openssl x509 -noout -enddate 2>/dev/null)

  if [ -z "$CERT_INFO" ]; then
    echo "[ERROR] Could not retrieve certificate for $DOMAIN"
    continue
  fi

  EXPIRY=${CERT_INFO#notAfter=}
  DAYS=$(( ( $(date -d "$EXPIRY" +%s) - $(date +%s) ) / 86400 ))

  if [ "$DAYS" -le "$THRESHOLD" ]; then
    echo "[ALERT] $DOMAIN certificate expires in $DAYS days"
  else
    echo "$DOMAIN certificate is valid for $DAYS days"
  fi
done
