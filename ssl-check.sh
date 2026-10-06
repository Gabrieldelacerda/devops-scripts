#!/bin/bash

if [ "$#" -gt 0 ]; then
  DOMAINS=("$@")
else
  DOMAINS=("google.com" "github.com")
fi

THRESHOLD=${THRESHOLD:-30}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] THRESHOLD must be a non-negative integer"
  exit 1
fi

FAILED=0

for DOMAIN in "${DOMAINS[@]}"; do
  CERT_INFO=$(echo | openssl s_client \
    -connect "$DOMAIN:443" \
    -servername "$DOMAIN" \
    2>/dev/null | openssl x509 -noout -enddate 2>/dev/null)

  if [ -z "$CERT_INFO" ]; then
    echo "[ERROR] Could not retrieve certificate for $DOMAIN"
    FAILED=1
    continue
  fi

  EXPIRY=${CERT_INFO#notAfter=}
  EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s 2>/dev/null)

  if [ -z "$EXPIRY_EPOCH" ]; then
    echo "[ERROR] Could not parse certificate expiry for $DOMAIN"
    FAILED=1
    continue
  fi

  DAYS=$(( (EXPIRY_EPOCH - $(date +%s)) / 86400 ))

  if [ "$DAYS" -le "$THRESHOLD" ]; then
    echo "[ALERT] $DOMAIN certificate expires in $DAYS days"
    FAILED=1
  else
    echo "[ OK ] $DOMAIN certificate is valid for $DAYS days"
  fi
done

exit "$FAILED"
