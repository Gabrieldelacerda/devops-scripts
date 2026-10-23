#!/usr/bin/env bash
set -o pipefail

if [ "$#" -gt 0 ]; then
  DOMAINS=("$@")
else
  DOMAINS=("google.com" "github.com")
fi

THRESHOLD=${THRESHOLD:-30}
TLS_TIMEOUT=${TLS_TIMEOUT-5}

if ! [[ "$THRESHOLD" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] THRESHOLD must be a non-negative integer"
  exit 1
fi

if ! [[ "$TLS_TIMEOUT" =~ ^([1-9]|[12][0-9]|30)$ ]]; then
  echo "[ERROR] TLS_TIMEOUT must be an integer between 1 and 30 seconds" >&2
  exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
  echo "[ERROR] Required command not found: timeout" >&2
  exit 1
fi

FAILED=0

for DOMAIN in "${DOMAINS[@]}"; do
  if ! CERT_INFO=$(printf '\n' | timeout "$TLS_TIMEOUT" openssl s_client \
    -connect "$DOMAIN:443" \
    -servername "$DOMAIN" \
    2>/dev/null | openssl x509 -noout -enddate 2>/dev/null); then
    echo "[ERROR] Could not retrieve certificate for $DOMAIN"
    FAILED=1
    continue
  fi

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
